import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:polleria_movil/data/app_storage.dart';
import 'package:polleria_movil/data/restaurant_store.dart';
import 'package:polleria_movil/models/app_notification.dart';
import 'package:polleria_movil/screens/order_detail.dart';
import 'package:polleria_movil/services/inactivity_service.dart';

class PusherService extends ChangeNotifier {
  PusherService._();

  static final PusherService instance = PusherService._();

  // Valores configurables en tiempo de compilación con --dart-define.
  // El workflow de GitHub Actions los inyecta desde variables/secretos.
  static const String defaultAppKey = String.fromEnvironment(
    'PUSHER_APP_KEY',
    defaultValue: 'a442712ed0da505c97d1',
  );
  static const String defaultCluster = String.fromEnvironment(
    'PUSHER_CLUSTER',
    defaultValue: 'us2',
  );
  static const int defaultPort = int.fromEnvironment(
    'PUSHER_PORT',
    defaultValue: 443,
  );
  static const bool defaultUseTLS = bool.fromEnvironment(
    'PUSHER_USE_TLS',
    defaultValue: true,
  );
  static const int maxStoredNotifications = 50;

  PusherChannelsClient? _client;
  final List<StreamSubscription> _subscriptions = [];
  final List<AppNotification> _notifications = [];

  bool _isInitialized = false;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  bool get isInitialized => _isInitialized;
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  static bool get isTestEnvironment {
    try {
      return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  /// Inicializa el servicio de Pusher y carga notificaciones guardadas
  void init({
    String appKey = defaultAppKey,
    String cluster = defaultCluster,
    bool autoConnect = true,
  }) {
    if (_isInitialized) return;
    _isInitialized = true;

    _loadStoredNotifications();

    if (autoConnect && !isTestEnvironment) {
      connect(appKey: appKey, cluster: cluster);
    }
  }

  /// Carga notificaciones guardadas en almacenamiento local
  void _loadStoredNotifications() {
    try {
      final stored = AppStorage.getNotifications();
      if (stored != null && stored.isNotEmpty) {
        _notifications.clear();
        for (final item in stored) {
          try {
            _notifications.add(AppNotification.fromJson(item));
          } catch (_) {}
        }
      }
    } catch (e) {
      developer.log('Error al cargar notificaciones guardadas: $e');
    }
  }

  /// Guarda las notificaciones en almacenamiento local
  void _persistNotifications() {
    try {
      final jsonList = _notifications
          .take(maxStoredNotifications)
          .map((n) => n.toJson())
          .toList();
      AppStorage.setNotifications(jsonList);
    } catch (e) {
      developer.log('Error al guardar notificaciones: $e');
    }
  }

  /// Conecta a Pusher y se suscribe a los canales requeridos
  void connect({
    String appKey = defaultAppKey,
    String cluster = defaultCluster,
    bool useTLS = defaultUseTLS,
  }) {
    if (_client != null) {
      disconnect();
    }

    try {
      final options = PusherChannelsOptions.fromCluster(
        scheme: useTLS ? 'wss' : 'ws',
        cluster: cluster,
        key: appKey,
        port: defaultPort,
      );

      _client = PusherChannelsClient.websocket(
        options: options,
        connectionErrorHandler: (exception, trace, refresh) async {
          developer.log('Error de conexión Pusher: $exception');
          _isConnected = false;
          notifyListeners();
          refresh();
        },
      );

      // Canales a escuchar
      final ordersChannel = _client!.publicChannel('orders');
      final tablesChannel = _client!.publicChannel('tables');
      final reportsChannel = _client!.publicChannel('reports');

      // Escuchar eventos de órdenes
      _bindChannelEvent(ordersChannel, 'new-order');
      _bindChannelEvent(ordersChannel, 'order-created');
      _bindChannelEvent(ordersChannel, 'status-updated');
      _bindChannelEvent(ordersChannel, 'payment-updated');
      _bindChannelEvent(ordersChannel, 'order-accepted');

      // Escuchar eventos de mesas
      _bindChannelEvent(tablesChannel, 'call-waiter');
      _bindChannelEvent(tablesChannel, 'request-bill');
      _bindChannelEvent(tablesChannel, 'table-alert');

      // Escuchar eventos de reportes
      _bindChannelEvent(reportsChannel, 'report-ready');
      _bindChannelEvent(reportsChannel, 'report-completed');
      _bindChannelEvent(reportsChannel, 'report-failed');

      // Manejar conexión establecida y reconexiones automáticas
      _subscriptions.add(
        _client!.onConnectionEstablished.listen((_) {
          developer.log('Conexión con Pusher establecida con éxito.');
          _isConnected = true;
          notifyListeners();

          ordersChannel.subscribeIfNotUnsubscribed();
          tablesChannel.subscribeIfNotUnsubscribed();
          reportsChannel.subscribeIfNotUnsubscribed();
        }),
      );

      unawaited(_client!.connect());
    } catch (e) {
      developer.log('Error al inicializar Pusher client: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  void _bindChannelEvent(PublicChannel channel, String eventName) {
    _subscriptions.add(
      channel.bind(eventName).listen((event) {
        final data = event.tryGetDataAsMap() ?? _tryParseData(event.data);
        handleRawEvent(channel.name, event.name, data);
      }),
    );
  }

  Map<String, dynamic> _tryParseData(dynamic rawData) {
    if (rawData is Map<String, dynamic>) return rawData;
    if (rawData is Map) return Map<String, dynamic>.from(rawData);
    if (rawData is String) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  /// Procesa un evento en crudo recibido de Pusher
  void handleRawEvent(String channel, String eventName, dynamic rawData) {
    final data = _tryParseData(rawData);
    final notification = _createNotificationFromEvent(eventName, data);
    addNotification(notification);

    // Si es un evento relacionado a pedidos o mesas, actualizar el store en tiempo real
    if (channel == 'orders' ||
        channel == 'tables' ||
        eventName.contains('order')) {
      if (!isTestEnvironment) {
        RestaurantStore.instance.loadOrdersFromApi();
      }
    }
  }

  AppNotification _createNotificationFromEvent(
    String eventName,
    Map<String, dynamic> data,
  ) {
    final now = DateTime.now();
    final eventLower = eventName.toLowerCase();
    final type = NotificationType.fromEventName(eventName);

    final id =
        data['id'] ??
        data['orderId'] ??
        data['order']?['id'] ??
        now.millisecondsSinceEpoch.toString();

    final rawTable =
        data['tableNumber'] ?? data['table'] ?? data['order']?['tableNumber'];
    final tableNum = _parseTableNumber(rawTable);

    final customerName =
        data['customerName']?.toString() ??
        data['customer']?['name']?.toString() ??
        (tableNum != null ? 'Mesa $tableNum' : 'Cliente');

    final amountNum =
        data['totalAmount'] ?? data['order']?['totalAmount'] ?? data['amount'];
    final amount = amountNum is num
        ? amountNum.toDouble()
        : double.tryParse(amountNum?.toString() ?? '');

    String title;
    String message;

    switch (type) {
      case NotificationType.newOrder:
        final orderStr = id.toString().isNotEmpty ? '#$id' : '';
        title = '🍗 ¡Nuevo Pedido $orderStr!';
        final totalText = amount != null
            ? ' • Total: S/ ${amount.toStringAsFixed(2)}'
            : '';
        message =
            '$customerName${tableNum != null ? ' (Mesa $tableNum)' : ''}$totalText';
        break;

      case NotificationType.statusUpdated:
        final status = data['status']?.toString() ?? 'Actualizado';
        title = '📋 Pedido #$id: Estado Actualizado';
        message = 'El pedido de $customerName cambió al estado: "$status"';
        break;

      case NotificationType.paymentUpdated:
        final paymentStatus = data['paymentStatus']?.toString() ?? 'Aprobado';
        title = '💳 Pago de Pedido #$id';
        final totalText = amount != null
            ? ' • S/ ${amount.toStringAsFixed(2)}'
            : '';
        message = 'Estado de pago: $paymentStatus$totalText';
        break;

      case NotificationType.orderAccepted:
        title = '🛵 Pedido #$id en Entrega';
        message =
            'El pedido para $customerName fue aceptado por el repartidor.';
        break;

      case NotificationType.callWaiter:
        title = '🔔 Mesa ${tableNum ?? ''}: Llamada de Mozo';
        message =
            data['message']?.toString() ??
            'El comensal en Mesa ${tableNum ?? ''} solicita atención inmediata.';
        break;

      case NotificationType.requestBill:
        title = '🧾 Mesa ${tableNum ?? ''}: Solicitud de Cuenta';
        message =
            data['message']?.toString() ??
            'El comensal en Mesa ${tableNum ?? ''} ha solicitado la cuenta.';
        break;

      case NotificationType.tableAlert:
        title = '⚠️ Mesa ${tableNum ?? ''}: Alerta';
        message =
            data['message']?.toString() ??
            'Alerta registrada en Mesa ${tableNum ?? ''}.';
        break;

      case NotificationType.reportReady:
        title = '📊 Reporte Listo';
        message =
            data['fileName']?.toString() ??
            data['message']?.toString() ??
            'El reporte ha sido generado exitosamente.';
        break;

      case NotificationType.reportFailed:
        title = '❌ Error en Reporte';
        message =
            data['message']?.toString() ??
            'No se pudo generar el reporte solicitado.';
        break;

      case NotificationType.general:
        title = data['title']?.toString() ?? 'Notificación';
        message =
            data['message']?.toString() ?? 'Nuevo evento recibido: $eventLower';
        break;
    }

    return AppNotification(
      id: '${eventName}_${id}_${now.millisecondsSinceEpoch}',
      title: title,
      message: message,
      timestamp: now,
      type: type,
      orderId: int.tryParse(id.toString()),
      tableNumber: tableNum,
      amount: amount,
      customerName: customerName,
      status: data['status']?.toString(),
      isRead: false,
    );
  }

  int? _parseTableNumber(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    final str = value.toString().replaceAll(RegExp(r'[^0-9]'), '').trim();
    return int.tryParse(str);
  }

  /// Agrega una notificación a la lista, retroalimenta visualmente y notifica
  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    if (_notifications.length > maxStoredNotifications) {
      _notifications.removeRange(maxStoredNotifications, _notifications.length);
    }

    _persistNotifications();
    notifyListeners();

    _provideFeedback();
    _showInAppNotification(notification);
  }

  void _provideFeedback() {
    if (isTestEnvironment) return;
    try {
      HapticFeedback.mediumImpact().catchError((_) {});
      SystemSound.play(SystemSoundType.alert).catchError((_) {});
    } catch (_) {}
  }

  void _showInAppNotification(AppNotification notification) {
    if (isTestEnvironment) return;
    final context = InactivityService.instance.navigatorKey.currentContext;
    if (context == null) return;

    try {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          backgroundColor: notification.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 6,
          content: Row(
            children: [
              Icon(notification.icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          action: notification.tableNumber != null
              ? SnackBarAction(
                  label: 'VER MESA',
                  textColor: Colors.amberAccent,
                  onPressed: () {
                    final nav =
                        InactivityService.instance.navigatorKey.currentState;
                    if (nav != null) {
                      nav.push(
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(
                            tableNumber: notification.tableNumber!,
                          ),
                        ),
                      );
                    }
                  },
                )
              : null,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      developer.log('Error al mostrar SnackBar flotante: $e');
    }
  }

  /// Marca una notificación como leída
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _persistNotifications();
      notifyListeners();
    }
  }

  /// Marca todas las notificaciones como leídas
  void markAllAsRead() {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      _persistNotifications();
      notifyListeners();
    }
  }

  /// Limpia todas las notificaciones recibidas
  void clearAll() {
    if (_notifications.isNotEmpty) {
      _notifications.clear();
      _persistNotifications();
      notifyListeners();
    }
  }

  /// Desconecta el cliente de Pusher
  void disconnect() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    if (_client != null) {
      unawaited(_client!.disconnect());
      _client = null;
    }

    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _isInitialized = false;
    super.dispose();
  }
}

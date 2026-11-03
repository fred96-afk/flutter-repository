import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:polleria_movil/api/api_config.dart';
import 'package:polleria_movil/theme/theme_controller.dart';

/// Servicio de almacenamiento local con Hive para persistir configuraciones:
/// - Modo de tema (Claro / Oscuro)
/// - Token de autenticación de inicio de sesión
/// - URL base personalizada del backend
/// - Timestamps de sesión (actividad y caducidad)
class AppStorage {
  AppStorage._();

  static const String boxName = 'polleria_storage';

  static const String keyThemeMode = 'theme_mode';
  static const String keyAuthToken = 'auth_token';
  static const String keyBaseUrl = 'backend_base_url';
  static const String keyLastActivity = 'last_activity_ms';
  static const String keyTokenIssuedAt = 'token_issued_at_ms';
  static const String keyUserData = 'user_data';
  static const String keyCachedMenu = 'cached_menu_json';
  static const String keyTableOrders = 'table_orders_json';
  static const String keyNotifications = 'notifications_json';

  static Box<dynamic>? _box;
  static final Map<String, dynamic> _memoryFallback = {};

  /// Indica si la caja de Hive está inicializada y abierta
  static bool get isInitialized => _box != null && _box!.isOpen;

  /// Inicializa Hive y abre la caja de almacenamiento en disco
  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox<dynamic>(boxName);
    } catch (e) {
      debugPrint('AppStorage init (fallback en memoria activado): $e');
    }

    restoreSavedSettings();
  }

  /// Inicialización manual para pruebas unitarias con una caja específica
  @visibleForTesting
  static Future<void> initForTesting([Box<dynamic>? testBox]) async {
    _box = testBox;
    _memoryFallback.clear();
    restoreSavedSettings();
  }

  /// Restaura los valores persistidos de Hive a sus controladores activos
  static void restoreSavedSettings() {
    // 1. Restaurar tema guardado
    final savedTheme = getThemeMode();
    if (savedTheme != null) {
      ThemeController.instance.setThemeMode(savedTheme, persist: false);
    }

    // 2. Restaurar token de inicio de sesión
    final savedToken = getAuthToken();
    if (savedToken != null && savedToken.isNotEmpty) {
      ApiConfig.instance.setAuthToken(savedToken, persist: false);
    }

    // 3. Restaurar URL de backend si fue personalizada
    final savedBaseUrl = getBaseUrl();
    if (savedBaseUrl != null && savedBaseUrl.isNotEmpty) {
      ApiConfig.instance.setBaseUrl(savedBaseUrl, persist: false);
    }
  }

  // ==========================================
  // PERSISTENCIA DEL TEMA
  // ==========================================

  /// Obtiene el modo de tema guardado
  static ThemeMode? getThemeMode() {
    final value = _box != null && _box!.isOpen
        ? _box!.get(keyThemeMode)
        : _memoryFallback[keyThemeMode];

    if (value == 'dark') return ThemeMode.dark;
    if (value == 'light') return ThemeMode.light;
    if (value == 'system') return ThemeMode.system;
    return null;
  }

  /// Guarda el modo de tema en Hive
  static Future<void> setThemeMode(ThemeMode mode) async {
    final value = mode.name;
    _memoryFallback[keyThemeMode] = value;
    if (_box != null && _box!.isOpen) {
      await _box!.put(keyThemeMode, value);
    }
  }

  // ==========================================
  // PERSISTENCIA DEL TOKEN DE AUTENTICACIÓN
  // ==========================================

  /// Obtiene el token de sesión guardado
  static String? getAuthToken() {
    final value = _box != null && _box!.isOpen
        ? _box!.get(keyAuthToken)
        : _memoryFallback[keyAuthToken];
    return value is String && value.isNotEmpty ? value : null;
  }

  /// Guarda o elimina el token de sesión en Hive
  static Future<void> setAuthToken(String? token) async {
    if (token == null || token.isEmpty) {
      _memoryFallback.remove(keyAuthToken);
      _memoryFallback.remove(keyLastActivity);
      _memoryFallback.remove(keyTokenIssuedAt);
      _memoryFallback.remove(keyUserData);
      if (_box != null && _box!.isOpen) {
        await _box!.delete(keyAuthToken);
      }
      if (_box != null && _box!.isOpen) {
        await _box!.delete(keyLastActivity);
      }
      if (_box != null && _box!.isOpen) {
        await _box!.delete(keyTokenIssuedAt);
      }
      if (_box != null && _box!.isOpen) {
        await _box!.delete(keyUserData);
      }
    } else {
      _memoryFallback[keyAuthToken] = token;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      _memoryFallback[keyLastActivity] = nowMs;
      _memoryFallback[keyTokenIssuedAt] = nowMs;
      if (_box != null && _box!.isOpen) {
        await _box!.put(keyAuthToken, token);
      }
      if (_box != null && _box!.isOpen) {
        await _box!.put(keyLastActivity, nowMs);
      }
      if (_box != null && _box!.isOpen) {
        await _box!.put(keyTokenIssuedAt, nowMs);
      }
    }
  }

  /// Obtiene la fecha/hora de última actividad registrada
  static DateTime? getLastActivity() {
    final value = _box != null && _box!.isOpen
        ? _box!.get(keyLastActivity)
        : _memoryFallback[keyLastActivity];
    if (value is int && value > 0) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }

  /// Actualiza la fecha/hora de última actividad
  static Future<void> setLastActivity(DateTime time) async {
    final value = time.millisecondsSinceEpoch;
    _memoryFallback[keyLastActivity] = value;
    if (_box != null && _box!.isOpen) {
      await _box!.put(keyLastActivity, value);
    }
  }

  /// Obtiene la fecha/hora en que fue emitido el token actual
  static DateTime? getTokenIssuedAt() {
    final value = _box != null && _box!.isOpen
        ? _box!.get(keyTokenIssuedAt)
        : _memoryFallback[keyTokenIssuedAt];
    if (value is int && value > 0) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }

  /// Guarda la fecha/hora de emisión del token
  static Future<void> setTokenIssuedAt(DateTime time) async {
    final value = time.millisecondsSinceEpoch;
    _memoryFallback[keyTokenIssuedAt] = value;
    if (_box != null && _box!.isOpen) {
      await _box!.put(keyTokenIssuedAt, value);
    }
  }

  /// Limpia los timestamps de sesión
  static Future<void> clearSessionTimestamps() async {
    _memoryFallback.remove(keyLastActivity);
    _memoryFallback.remove(keyTokenIssuedAt);
    if (_box != null && _box!.isOpen) {
      await _box!.delete(keyLastActivity);
    }
    if (_box != null && _box!.isOpen) {
      await _box!.delete(keyTokenIssuedAt);
    }
  }

  // ==========================================
  // PERSISTENCIA DEL PERFIL DE USUARIO (HIVE)
  // ==========================================

  /// Obtiene los datos del usuario en sesión guardados en Hive
  static Map<String, dynamic>? getUserData() {
    final value = _box != null && _box!.isOpen
        ? _box!.get(keyUserData)
        : _memoryFallback[keyUserData];
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  /// Guarda o elimina el perfil del usuario en Hive
  static Future<void> setUserData(Map<String, dynamic>? data) async {
    if (data == null) {
      _memoryFallback.remove(keyUserData);
      if (_box != null && _box!.isOpen) {
        await _box!.delete(keyUserData);
      }
    } else {
      _memoryFallback[keyUserData] = data;
      if (_box != null && _box!.isOpen) {
        await _box!.put(keyUserData, data);
      }
    }
  }

  // ==========================================
  // PERSISTENCIA DEL CATÁLOGO DE MENÚ (HIVE)
  // ==========================================

  /// Obtiene el menú de productos cacheado en Hive
  static List<Map<String, dynamic>>? getCachedMenu() {
    final value = _box != null && _box!.isOpen
        ? _box!.get(keyCachedMenu)
        : _memoryFallback[keyCachedMenu];
    if (value is List) {
      return value.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return null;
  }

  /// Guarda la lista de productos del menú en Hive para soporte offline
  static Future<void> setCachedMenu(List<Map<String, dynamic>>? menu) async {
    if (menu == null || menu.isEmpty) {
      _memoryFallback.remove(keyCachedMenu);
      if (_box != null && _box!.isOpen) {
        await _box!.delete(keyCachedMenu);
      }
    } else {
      _memoryFallback[keyCachedMenu] = menu;
      if (_box != null && _box!.isOpen) {
        await _box!.put(keyCachedMenu, menu);
      }
    }
  }

  // ==========================================
  // PERSISTENCIA DE PEDIDOS DE MESAS (HIVE)
  // ==========================================

  /// Obtiene los pedidos activos por mesa guardados en Hive
  static Map<String, List<Map<String, dynamic>>>? getTableOrders() {
    final value = _box != null && _box!.isOpen
        ? _box!.get(keyTableOrders)
        : _memoryFallback[keyTableOrders];
    if (value is Map) {
      final result = <String, List<Map<String, dynamic>>>{};
      value.forEach((key, val) {
        final tableNumber = key.toString().trim();
        if (tableNumber.isNotEmpty && val is List) {
          result[tableNumber] = val
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      });
      return result;
    }
    return null;
  }

  /// Guarda los pedidos pendientes de las mesas en Hive
  static Future<void> setTableOrders(
    Map<String, List<Map<String, dynamic>>>? orders,
  ) async {
    if (orders == null || orders.isEmpty) {
      _memoryFallback.remove(keyTableOrders);
      if (_box != null && _box!.isOpen) {
        await _box!.delete(keyTableOrders);
      }
    } else {
      final storable = <String, dynamic>{};
      orders.forEach((table, items) {
        storable[table] = items;
      });
      _memoryFallback[keyTableOrders] = storable;
      if (_box != null && _box!.isOpen) {
        await _box!.put(keyTableOrders, storable);
      }
    }
  }

  // ==========================================
  // PERSISTENCIA DE LA URL DEL BACKEND
  // ==========================================

  /// Obtiene la URL personalizada guardada
  static String? getBaseUrl() {
    final value = _box != null && _box!.isOpen
        ? _box!.get(keyBaseUrl)
        : _memoryFallback[keyBaseUrl];
    return value is String && value.isNotEmpty ? value : null;
  }

  /// Guarda la URL del backend en Hive
  static Future<void> setBaseUrl(String? url) async {
    if (url == null || url.isEmpty) {
      _memoryFallback.remove(keyBaseUrl);
      if (_box != null && _box!.isOpen) {
        await _box!.delete(keyBaseUrl);
      }
    } else {
      _memoryFallback[keyBaseUrl] = url;
      if (_box != null && _box!.isOpen) {
        await _box!.put(keyBaseUrl, url);
      }
    }
  }

  // ==========================================
  // NOTIFICACIONES (PUSHER)
  // ==========================================

  /// Obtiene la lista de notificaciones guardadas en Hive
  static List<Map<String, dynamic>>? getNotifications() {
    final value = _box != null && _box!.isOpen
        ? _box!.get(keyNotifications)
        : _memoryFallback[keyNotifications];
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return null;
  }

  /// Guarda la lista de notificaciones en Hive
  static Future<void> setNotifications(List<Map<String, dynamic>> items) async {
    _memoryFallback[keyNotifications] = items;
    if (_box != null && _box!.isOpen) {
      await _box!.put(keyNotifications, items);
    }
  }
}

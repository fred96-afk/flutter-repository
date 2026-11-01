import 'package:flutter_test/flutter_test.dart';
import 'package:polleria_movil/models/app_notification.dart';
import 'package:polleria_movil/services/pusher_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PusherService.instance.clearAll();
  });

  group('AppNotification Model', () {
    test('serializes to and from JSON correctly', () {
      final now = DateTime(2026, 11, 1, 12, 0);
      final notification = AppNotification(
        id: 'test_1',
        title: '🍗 ¡Nuevo Pedido #10!',
        message: 'Mesa 4 • Total: S/ 65.00',
        timestamp: now,
        type: NotificationType.newOrder,
        orderId: 10,
        tableNumber: 4,
        amount: 65.0,
        customerName: 'Augusto',
        status: 'Pending',
        isRead: false,
      );

      final json = notification.toJson();
      expect(json['id'], 'test_1');
      expect(json['title'], '🍗 ¡Nuevo Pedido #10!');
      expect(json['type'], 'newOrder');
      expect(json['orderId'], 10);
      expect(json['tableNumber'], 4);
      expect(json['amount'], 65.0);

      final fromJson = AppNotification.fromJson(json);
      expect(fromJson.id, 'test_1');
      expect(fromJson.title, '🍗 ¡Nuevo Pedido #10!');
      expect(fromJson.type, NotificationType.newOrder);
      expect(fromJson.orderId, 10);
      expect(fromJson.tableNumber, 4);
      expect(fromJson.amount, 65.0);
      expect(fromJson.isRead, isFalse);
    });

    test('copyWith updates isRead state correctly', () {
      final notification = AppNotification(
        id: 'test_2',
        title: 'Title',
        message: 'Message',
        timestamp: DateTime.now(),
        type: NotificationType.callWaiter,
        isRead: false,
      );

      final updated = notification.copyWith(isRead: true);
      expect(updated.isRead, isTrue);
      expect(notification.isRead, isFalse);
    });

    test('NotificationType maps event names correctly', () {
      expect(NotificationType.fromEventName('new-order'), NotificationType.newOrder);
      expect(NotificationType.fromEventName('order-created'), NotificationType.newOrder);
      expect(NotificationType.fromEventName('status-updated'), NotificationType.statusUpdated);
      expect(NotificationType.fromEventName('payment-updated'), NotificationType.paymentUpdated);
      expect(NotificationType.fromEventName('order-accepted'), NotificationType.orderAccepted);
      expect(NotificationType.fromEventName('call-waiter'), NotificationType.callWaiter);
      expect(NotificationType.fromEventName('request-bill'), NotificationType.requestBill);
      expect(NotificationType.fromEventName('table-alert'), NotificationType.tableAlert);
      expect(NotificationType.fromEventName('report-ready'), NotificationType.reportReady);
      expect(NotificationType.fromEventName('report-failed'), NotificationType.reportFailed);
      expect(NotificationType.fromEventName('unknown-event'), NotificationType.general);
    });
  });

  group('PusherService Notification Handling', () {
    test('Service initializes with default Pusher constants', () {
      final pusher = PusherService.instance;
      pusher.init();

      expect(PusherService.defaultAppKey, 'a442712ed0da505c97d1');
      expect(PusherService.defaultCluster, 'us2');
      expect(PusherService.defaultPort, 443);
      expect(pusher.isInitialized, isTrue);
    });

    test('handles new-order raw event and creates notification', () {
      final pusher = PusherService.instance;
      pusher.init();

      pusher.handleRawEvent('orders', 'new-order', {
        'id': 105,
        'tableNumber': '3',
        'customerName': 'Juan Pérez',
        'totalAmount': 85.50,
        'status': 'Pending',
      });

      expect(pusher.notifications.length, 1);
      final notif = pusher.notifications.first;
      expect(notif.type, NotificationType.newOrder);
      expect(notif.orderId, 105);
      expect(notif.tableNumber, 3);
      expect(notif.title, contains('¡Nuevo Pedido #105!'));
      expect(notif.message, contains('Juan Pérez'));
      expect(notif.message, contains('85.50'));
      expect(pusher.unreadCount, 1);
    });

    test('handles status-updated event correctly', () {
      final pusher = PusherService.instance;
      pusher.init();

      pusher.handleRawEvent('orders', 'status-updated', {
        'id': 105,
        'tableNumber': '3',
        'customerName': 'Juan Pérez',
        'status': 'En Preparación',
      });

      expect(pusher.notifications.length, 1);
      final notif = pusher.notifications.first;
      expect(notif.type, NotificationType.statusUpdated);
      expect(notif.title, contains('Estado Actualizado'));
      expect(notif.message, contains('En Preparación'));
    });

    test('handles call-waiter and request-bill events from tables channel', () {
      final pusher = PusherService.instance;
      pusher.init();

      pusher.handleRawEvent('tables', 'call-waiter', {
        'tableNumber': '7',
        'message': 'Mesa 7 necesita atención',
      });

      pusher.handleRawEvent('tables', 'request-bill', {
        'tableNumber': '7',
        'message': 'Mesa 7 pide la cuenta',
      });

      expect(pusher.notifications.length, 2);
      expect(pusher.notifications[0].type, NotificationType.requestBill);
      expect(pusher.notifications[0].tableNumber, 7);
      expect(pusher.notifications[1].type, NotificationType.callWaiter);
      expect(pusher.notifications[1].tableNumber, 7);
      expect(pusher.unreadCount, 2);
    });

    test('handles report events from reports channel', () {
      final pusher = PusherService.instance;
      pusher.init();

      pusher.handleRawEvent('reports', 'report-ready', {
        'fileName': 'ventas_octubre.pdf',
      });

      pusher.handleRawEvent('reports', 'report-failed', {
        'message': 'Error de base de datos',
      });

      expect(pusher.notifications.length, 2);
      expect(pusher.notifications[0].type, NotificationType.reportFailed);
      expect(pusher.notifications[1].type, NotificationType.reportReady);
    });

    test('markAsRead and markAllAsRead update unreadCount', () {
      final pusher = PusherService.instance;
      pusher.init();

      pusher.handleRawEvent('orders', 'new-order', {'id': 1});
      pusher.handleRawEvent('orders', 'new-order', {'id': 2});
      expect(pusher.unreadCount, 2);

      pusher.markAsRead(pusher.notifications[0].id);
      expect(pusher.unreadCount, 1);
      expect(pusher.notifications[0].isRead, isTrue);
      expect(pusher.notifications[1].isRead, isFalse);

      pusher.markAllAsRead();
      expect(pusher.unreadCount, 0);
      expect(pusher.notifications.every((n) => n.isRead), isTrue);
    });

    test('clearAll removes all notifications', () {
      final pusher = PusherService.instance;
      pusher.init();

      pusher.handleRawEvent('orders', 'new-order', {'id': 1});
      pusher.handleRawEvent('orders', 'new-order', {'id': 2});
      expect(pusher.notifications.length, 2);

      pusher.clearAll();
      expect(pusher.notifications.isEmpty, isTrue);
      expect(pusher.unreadCount, 0);
    });
  });
}

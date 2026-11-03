import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polleria_movil/models/app_notification.dart';
import 'package:polleria_movil/screens/app_drawer.dart';
import 'package:polleria_movil/services/pusher_service.dart';
import 'package:polleria_movil/widgets/notification_icon_button.dart';
import 'package:polleria_movil/widgets/notifications_sheet.dart';

void main() {
  setUp(() {
    PusherService.instance.clearAll();
  });

  group('NotificationIconButton and NotificationsSheet UI', () {
    testWidgets('NotificationIconButton shows badge when unreadCount > 0', (
      tester,
    ) async {
      final pusher = PusherService.instance;
      pusher.init();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(actions: const [NotificationIconButton()]),
          ),
        ),
      );

      // Initially 0 unread: badge text not visible
      expect(find.byType(NotificationIconButton), findsOneWidget);
      expect(find.text('1'), findsNothing);

      // Add a notification
      pusher.handleRawEvent('orders', 'new-order', {
        'id': 101,
        'tableNumber': '5',
        'customerName': 'Carlos',
        'totalAmount': 75.0,
      });
      await tester.pumpAndSettle();

      // Badge displays '1'
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('Tapping NotificationIconButton opens NotificationsSheet', (
      tester,
    ) async {
      final pusher = PusherService.instance;
      pusher.init();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(actions: const [NotificationIconButton()]),
          ),
        ),
      );

      await tester.tap(find.byType(NotificationIconButton));
      await tester.pumpAndSettle();

      expect(find.text('Notificaciones'), findsOneWidget);
      expect(find.text('Sin notificaciones'), findsOneWidget);
    });

    testWidgets('NotificationsSheet displays notification cards and actions', (
      tester,
    ) async {
      final pusher = PusherService.instance;
      pusher.init();

      pusher.addNotification(
        AppNotification(
          id: 'test_n1',
          title: '🍗 ¡Nuevo Pedido #200!',
          message: 'Mesa 3 • Total: S/ 90.00',
          timestamp: DateTime.now(),
          type: NotificationType.newOrder,
          orderId: 200,
          tableNumber: '3',
          amount: 90.0,
          isRead: false,
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: NotificationsSheet())),
      );
      await tester.pumpAndSettle();

      expect(find.text('🍗 ¡Nuevo Pedido #200!'), findsOneWidget);
      expect(find.text('Mesa 3 • Total: S/ 90.00'), findsOneWidget);
      expect(find.text('Ver Mesa 3'), findsOneWidget);

      // Mark all as read action
      final markReadFinder = find.byTooltip('Marcar todas como leídas');
      expect(markReadFinder, findsOneWidget);
      await tester.tap(markReadFinder);
      await tester.pumpAndSettle();

      expect(pusher.unreadCount, 0);

      // Clear history action
      final clearFinder = find.byTooltip('Borrar historial');
      expect(clearFinder, findsOneWidget);
      await tester.tap(clearFinder);
      await tester.pumpAndSettle();

      expect(pusher.notifications.isEmpty, isTrue);
      expect(find.text('Sin notificaciones'), findsOneWidget);
    });

    testWidgets('AppDrawer displays Notificaciones tile with unread badge', (
      tester,
    ) async {
      final pusher = PusherService.instance;
      pusher.init();

      pusher.addNotification(
        AppNotification(
          id: 'test_n2',
          title: '🔔 Mesa 2: Mozo',
          message: 'Llamada de mozo',
          timestamp: DateTime.now(),
          type: NotificationType.callWaiter,
          tableNumber: '2',
          isRead: false,
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(drawer: AppDrawer(selectedRoute: '/home')),
        ),
      );

      // Open drawer
      final scaffoldState =
          tester.firstState(find.byType(Scaffold)) as ScaffoldState;
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Notificaciones'), findsOneWidget);
      expect(find.text('1'), findsWidgets); // Unread badge
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polleria_movil/api/api.dart';
import 'package:polleria_movil/app.dart';
import 'package:polleria_movil/data/restaurant_store.dart';
import 'package:polleria_movil/screens/order_detail.dart';
import 'package:polleria_movil/screens/orders.dart';
import 'package:polleria_movil/screens/ticket_print_screen.dart';
import 'package:polleria_movil/theme/app_theme.dart';
import 'package:polleria_movil/theme/theme_controller.dart';
import 'package:polleria_movil/widgets/theme_toggle_button.dart';

void main() {
  setUp(() {
    ApiConfig.instance.clearAuth();
    ThemeController.instance.setThemeMode(ThemeMode.light);
  });

  group('ThemeController', () {
    test('toggles between light and dark theme mode', () {
      final controller = ThemeController.instance;
      expect(controller.themeMode, ThemeMode.light);

      controller.toggleTheme();
      expect(controller.themeMode, ThemeMode.dark);

      controller.toggleTheme();
      expect(controller.themeMode, ThemeMode.light);
    });

    test('notifies listeners when theme is toggled', () {
      final controller = ThemeController.instance;
      var notified = false;
      controller.addListener(() {
        notified = true;
      });

      controller.toggleTheme();
      expect(notified, isTrue);
    });
  });

  group('Theme UI Toggle', () {
    testWidgets('Toggles theme from LoginScreen button', (tester) async {
      await tester.pumpWidget(const App());
      expect(ThemeController.instance.themeMode, ThemeMode.light);

      final toggleFinder = find.byType(ThemeToggleButton);
      expect(toggleFinder, findsOneWidget);

      // Verify initial icon is dark mode icon (indicating toggle to dark)
      expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);

      // Tap toggle button
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      expect(ThemeController.instance.themeMode, ThemeMode.dark);
      expect(find.byIcon(Icons.light_mode), findsOneWidget);

      // Tap toggle button again
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      expect(ThemeController.instance.themeMode, ThemeMode.light);
      expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    });

    testWidgets('Toggles theme from AppDrawer switch', (tester) async {
      await tester.pumpWidget(const App());

      // Login
      await tester.enterText(find.byType(TextFormField).first, 'augusto');
      await tester.enterText(find.byType(TextFormField).last, '123456');
      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();

      // Open drawer
      final scaffoldState = tester.firstState<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Modo oscuro'), findsOneWidget);
      expect(find.text('Desactivado'), findsOneWidget);

      // Tap switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(ThemeController.instance.themeMode, ThemeMode.dark);
      expect(find.text('Activado'), findsOneWidget);
    });

    testWidgets('OrderDetailScreen renders in light and dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const OrderDetailScreen(tableNumber: 1),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pedido · Mesa 1'), findsOneWidget);
      expect(find.text('Agregar productos'), findsOneWidget);
      expect(find.byType(ThemeToggleButton), findsOneWidget);
    });

    testWidgets('OrdersScreen renders in light and dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const OrdersScreen(attended: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pedidos pendientes'), findsOneWidget);
      expect(find.byType(ThemeToggleButton), findsOneWidget);
    });

    testWidgets('TicketPrintScreen renders in light and dark mode', (tester) async {
      final order = CompletedOrder(
        ticketNumber: 'T-001',
        tableNumber: 5,
        items: [
          OrderItem(product: RestaurantStore.menu.first, quantity: 2),
        ],
        completedAt: DateTime(2026, 10, 20, 14, 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: TicketPrintScreen(order: order),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vista previa del ticket'), findsOneWidget);
      expect(find.text('POLLERÍA EL GIGANTE'), findsOneWidget);
      expect(find.text('Ticket: T-001'), findsOneWidget);
      expect(find.byType(ThemeToggleButton), findsOneWidget);
    });
  });
}

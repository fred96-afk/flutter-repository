import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polleria_movil/data/restaurant_store.dart';
import 'package:polleria_movil/screens/order_detail.dart';
import 'package:polleria_movil/screens/ticket_print_screen.dart';

void main() {
  testWidgets('Visual feedback when adding and modifying products in table', (
    WidgetTester tester,
  ) async {
    final store = RestaurantStore.instance;
    store.clearTable(1);

    await tester.pumpWidget(
      const MaterialApp(
        home: OrderDetailScreen(tableNumber: 1),
      ),
    );

    // Initial state: table is empty
    expect(find.text('Aún no hay productos en esta mesa.'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);

    // Open menu modal
    await tester.tap(find.text('Agregar productos'));
    await tester.pumpAndSettle();

    expect(find.text('Menú · Mesa 1'), findsOneWidget);

    // Initially, no confirmation message is displayed
    expect(find.textContaining('agregado a Mesa 1'), findsNothing);

    // Tap "Agregar" on the first item
    final addButtons = find.widgetWithText(FilledButton, 'Agregar');
    expect(addButtons, findsWidgets);
    await tester.tap(addButtons.first);
    await tester.pumpAndSettle();

    // 1. Green feedback banner appears with confirmation
    expect(find.textContaining('agregado a Mesa 1'), findsOneWidget);

    // 2. Stepper with 1 appears
    expect(find.text('1'), findsWidgets);

    // 3. Bottom bar updates with item count
    expect(find.text('1 productos en Mesa 1'), findsOneWidget);
    expect(find.text('Listo (1)'), findsOneWidget);

    // 4. Tap the '+' button on the stepper in the bottom sheet to increment
    final plusButton = find.byTooltip('Agregar otra unidad').last;
    await tester.tap(plusButton);
    await tester.pumpAndSettle();

    // Feedback updates with ×2
    expect(find.textContaining('×2 en Mesa 1'), findsOneWidget);
    expect(find.text('2 productos en Mesa 1'), findsOneWidget);
    expect(find.text('Listo (2)'), findsOneWidget);

    // 5. Close bottom sheet by tapping "Listo"
    await tester.tap(find.text('Listo (2)'));
    await tester.pumpAndSettle();

    // Verify main screen now lists the items with 2×
    expect(find.text('2×'), findsOneWidget);
    expect(find.text('Aún no hay productos en esta mesa.'), findsNothing);
  });

  testWidgets('Product description with long text can expand and collapse', (
    WidgetTester tester,
  ) async {
    final store = RestaurantStore.instance;
    store.clearTable(1);
    store.setCustomMenu([
      const MenuProduct(
        id: '99',
        name: 'Super Banquete Especial Familiar',
        price: 99.90,
        icon: Icons.restaurant,
        category: MenuCategory.polloALaBrasa,
        description:
            'Pollo entero marinado con especias tradicionales peruanas, servido con porción generosa de papas fritas y ensalada fresca clásica de la casa.',
      ),
    ]);

    await tester.pumpWidget(
      const MaterialApp(
        home: OrderDetailScreen(tableNumber: 1),
      ),
    );

    // Open menu modal
    await tester.tap(find.text('Agregar productos'));
    await tester.pumpAndSettle();

    // Verify product name and description are visible
    expect(find.text('Super Banquete Especial Familiar'), findsOneWidget);
    expect(find.textContaining('Pollo entero marinado'), findsOneWidget);

    // Because description is long (> 40 chars), "Ver más" is visible
    expect(find.text('Ver más'), findsOneWidget);
    expect(find.text('Ver menos'), findsNothing);

    // Tap "Ver más" to expand description
    await tester.tap(find.text('Ver más'));
    await tester.pumpAndSettle();

    // Now "Ver menos" should be visible
    expect(find.text('Ver menos'), findsOneWidget);

    // Tap "Ver menos" to collapse description
    await tester.tap(find.text('Ver menos'));
    await tester.pumpAndSettle();

    expect(find.text('Ver más'), findsOneWidget);
    expect(find.text('Ver menos'), findsNothing);

    // Reset menu
    store.resetMenu();
  });

  testWidgets('Ticket displays full product name and description without collapsing', (
    WidgetTester tester,
  ) async {
    const product = MenuProduct(
      id: '1',
      name: 'Pollo a la Brasa (Entero) con cremas',
      price: 65.0,
      icon: Icons.restaurant,
      category: MenuCategory.polloALaBrasa,
      description: 'Pollo entero marinado con papas fritas y ensalada clásica',
    );

    final order = CompletedOrder(
      ticketNumber: 'TICK-101',
      tableNumber: 3,
      items: [
        OrderItem(product: product, quantity: 2),
      ],
      completedAt: DateTime(2026, 10, 22, 14, 0),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TicketPrintScreen(order: order),
      ),
    );
    await tester.pumpAndSettle();

    // Verify product name and full description are displayed without truncation
    expect(find.text('Pollo a la Brasa (Entero) con cremas'), findsOneWidget);
    expect(
      find.text('Pollo entero marinado con papas fritas y ensalada clásica'),
      findsOneWidget,
    );
    expect(find.text('2×'), findsOneWidget);
    expect(find.text('S/ 130.00'), findsWidgets);
  });
}

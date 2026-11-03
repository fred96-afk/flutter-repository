import 'package:flutter/material.dart';
import 'package:polleria_movil/data/restaurant_store.dart';
import 'package:polleria_movil/screens/app_drawer.dart';
import 'package:polleria_movil/screens/order_detail.dart';
import 'package:polleria_movil/screens/ticket_print_screen.dart';
import 'package:polleria_movil/widgets/notification_icon_button.dart';
import 'package:polleria_movil/widgets/theme_toggle_button.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key, required this.attended});

  final bool attended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final title = attended ? 'Pedidos atendidos' : 'Pedidos pendientes';
    final store = RestaurantStore.instance;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Sincronizar',
            icon: store.isLoadingOrders
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            onPressed: store.isLoadingOrders
                ? null
                : () async {
                    await store.loadOrdersFromApi();
                    if (context.mounted) {
                      final count = store
                          .tablesWithOrders(attended: attended)
                          .length;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$count pedido(s) sincronizado(s)'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
          ),
          const NotificationIconButton(),
          const ThemeToggleButton(),
        ],
      ),
      drawer: AppDrawer(
        selectedRoute: attended ? '/orders/attended' : '/orders/pending',
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final tables = store.tablesWithOrders(attended: attended);
          final rows = <_OrderRow>[
            for (final tableNumber in tables)
              _OrderRow(
                tableNumber: tableNumber,
                itemCount: store.itemCountFor(tableNumber),
                total: store.totalFor(tableNumber),
              ),
            if (attended)
              for (final order in store.completedOrders)
                _OrderRow(
                  tableNumber: order.tableNumber,
                  itemCount: order.itemCount,
                  total: order.total,
                  completedOrder: order,
                ),
          ];

          if (rows.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => store.loadOrdersFromApi(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.65,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              attended ? Icons.task_alt : Icons.receipt_long,
                              size: 72,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay ${title.toLowerCase()}',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              attended
                                  ? 'Los pedidos atendidos y tickets generados aparecerán aquí.'
                                  : 'Los pedidos aparecerán aquí cuando agregues productos a una mesa.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => store.loadOrdersFromApi(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final row = rows[index];
                final completedOrder = row.completedOrder;
                return Card(
                  color: theme.cardColor,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimaryContainer,
                      child: Text(row.tableNumber),
                    ),
                    title: Text(
                      store.displayNameFor(row.tableNumber),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${row.itemCount} productos · S/ ${row.total.toStringAsFixed(2)}'
                      '${completedOrder == null ? '' : ' · Ticket generado'}',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    onTap: completedOrder == null
                        ? () => Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderDetailScreen(
                                tableNumber: row.tableNumber,
                              ),
                            ),
                          )
                        : () => _showCompletedOrder(context, completedOrder),
                    trailing: completedOrder != null
                        ? Icon(
                            Icons.receipt_long,
                            color: isDark
                                ? const Color(0xFF48B383)
                                : Colors.green,
                          )
                        : attended
                        ? Icon(
                            Icons.task_alt,
                            color: isDark
                                ? const Color(0xFF48B383)
                                : Colors.green,
                          )
                        : IconButton(
                            tooltip: 'Marcar como atendido',
                            onPressed: () =>
                                store.markAttended(row.tableNumber),
                            icon: Icon(
                              Icons.check_circle_outline,
                              color: colorScheme.primary,
                            ),
                          ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCompletedOrder(BuildContext context, CompletedOrder order) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor:
            theme.dialogTheme.backgroundColor ?? colorScheme.surface,
        title: Text(
          'Pedido atendido',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ticket: ${order.ticketNumber}',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                Text(
                  'Mesa: ${order.tableNumber}',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                const Divider(),
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(
                            '${item.quantity}×',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.name,
                                softWrap: true,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              if (item.product.description != null &&
                                  item.product.description!
                                      .trim()
                                      .isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.product.description!,
                                  softWrap: true,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'S/ ${item.subtotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                Text(
                  'Total: S/ ${order.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketPrintScreen(order: order),
                ),
              );
            },
            icon: const Icon(Icons.print),
            label: const Text('Imprimir'),
          ),
        ],
      ),
    );
  }
}

class _OrderRow {
  const _OrderRow({
    required this.tableNumber,
    required this.itemCount,
    required this.total,
    this.completedOrder,
  });

  final String tableNumber;
  final int itemCount;
  final double total;
  final CompletedOrder? completedOrder;
}

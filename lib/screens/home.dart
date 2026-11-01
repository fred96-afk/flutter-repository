import 'package:flutter/material.dart';
import 'package:polleria_movil/data/restaurant_store.dart';
import 'package:polleria_movil/screens/app_drawer.dart';
import 'package:polleria_movil/screens/order_detail.dart';
import 'package:polleria_movil/widgets/notification_icon_button.dart';
import 'package:polleria_movil/widgets/theme_toggle_button.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  static const _tableCount = 18;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RestaurantStore.instance.loadAllFromApi();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final store = RestaurantStore.instance;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Pollería El Gigante'),
        actions: [
          AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              final isLoading = store.isLoadingOrders || store.isLoadingMenu;
              return IconButton(
                tooltip: 'Sincronizar',
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                onPressed: isLoading
                    ? null
                    : () async {
                        await store.loadAllFromApi();
                        if (context.mounted) {
                          final activeCount =
                              store.tablesWithOrders(attended: false).length;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Sincronizado: $activeCount mesa(s) activa(s), ${RestaurantStore.menu.length} producto(s)',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
              );
            },
          ),
          const NotificationIconButton(),
          const ThemeToggleButton(),
        ],
      ),
      drawer: const AppDrawer(selectedRoute: '/home'),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: IgnorePointer(
              child: Opacity(
                opacity: isDark ? 0.12 : 0.05,
                child: Image.asset(
                  'assets/images/polleria_logo.png',
                  width: 320,
                  height: 440,
                  fit: BoxFit.contain,
                  semanticLabel: 'Logo de fondo de Pollería El Gigante',
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: store,
            builder: (context, _) => LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1000
                    ? 4
                    : constraints.maxWidth >= 600
                    ? 3
                    : 2;
                return RefreshIndicator(
                  onRefresh: () => store.loadAllFromApi(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Mesas',
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (store.isLoadingOrders || store.isLoadingMenu)
                                    Row(
                                      children: [
                                        const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Sincronizando...',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${Home._tableCount} mesas · 4 personas por mesa · ${RestaurantStore.menu.length} productos en menú',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _floorHeader(context, 'Piso 1', 'Mesas 1 a 10'),
                      _tableGrid(
                        context,
                        store: store,
                        firstTable: 1,
                        count: 10,
                        columns: columns,
                      ),
                      _floorHeader(context, 'Piso 2', 'Mesas 11 a 18'),
                      _tableGrid(
                        context,
                        store: store,
                        firstTable: 11,
                        count: 8,
                        columns: columns,
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _floorHeader(BuildContext context, String title, String range) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      sliver: SliverToBoxAdapter(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              range,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableGrid(
    BuildContext context, {
    required RestaurantStore store,
    required int firstTable,
    required int count,
    required int columns,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate((context, index) {
          final tableNumber = firstTable + index;
          return _TableCard(
            tableNumber: tableNumber,
            occupied: store.isOccupied(tableNumber),
            itemCount: store.itemCountFor(tableNumber),
            total: store.totalFor(tableNumber),
            remoteOrder: store.remoteOrderFor(tableNumber),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(tableNumber: tableNumber),
              ),
            ),
          );
        }, childCount: count),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.12,
        ),
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({
    required this.tableNumber,
    required this.occupied,
    required this.itemCount,
    required this.total,
    this.remoteOrder,
    required this.onTap,
  });

  final int tableNumber;
  final bool occupied;
  final int itemCount;
  final double total;
  final dynamic remoteOrder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final color = occupied
        ? (isDark ? const Color(0xFFE58F75) : const Color(0xFF914F3A))
        : (isDark ? const Color(0xFF48B383) : const Color(0xFF168C5B));

    final cardBg = occupied
        ? (isDark ? const Color(0xFF38231D) : const Color(0xFFFFF1E8))
        : (isDark ? const Color(0xFF1B2E24) : const Color(0xFFE7F7ED));

    final badgeText = occupied
        ? (remoteOrder != null && remoteOrder.status != null
            ? remoteOrder.status.toString().toUpperCase()
            : 'OCUPADO')
        : 'LIBRE';

    return Card(
      margin: EdgeInsets.zero,
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.table_restaurant, color: color, size: 27),
                  const SizedBox(height: 5),
                  Text(
                    'Mesa $tableNumber',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    occupied
                        ? '$itemCount prod. · S/ ${total.toStringAsFixed(2)}'
                        : '4 personas',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: occupied
                          ? color
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:polleria_movil/api/models/table_models.dart';
import 'package:polleria_movil/data/restaurant_store.dart';
import 'package:polleria_movil/screens/app_drawer.dart';
import 'package:polleria_movil/screens/order_detail.dart';
import 'package:polleria_movil/widgets/notification_icon_button.dart';
import 'package:polleria_movil/widgets/theme_toggle_button.dart';

class Home extends StatefulWidget {
  const Home({super.key});

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
              final isLoading =
                  store.isLoadingOrders ||
                  store.isLoadingMenu ||
                  store.isLoadingTables;
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
                          final activeCount = store
                              .tablesWithOrders(attended: false)
                              .length;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Sincronizado: ${store.tables.length} mesas, '
                                '$activeCount mesa(s) activa(s), '
                                '${RestaurantStore.menu.length} producto(s)',
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
                final sectors = _groupTables(store.tables);
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
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurface,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  if (store.isLoadingOrders ||
                                      store.isLoadingMenu ||
                                      store.isLoadingTables)
                                    Row(
                                      children: [
                                        const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
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
                                '${store.tables.length} mesas · '
                                '${store.totalChairs} sillas · '
                                '${RestaurantStore.menu.length} productos en menú',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (sectors.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              'No hay mesas disponibles.',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      else
                        for (final sector in sectors) ...[
                          _sectorHeader(
                            context,
                            sector.name,
                            '${sector.tables.length} mesas',
                          ),
                          _tableGrid(
                            context,
                            store: store,
                            tables: sector.tables,
                            columns: columns,
                          ),
                        ],
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

  /// Agrupa las mesas por sector en el mismo orden que el mapa del frontend web.
  List<_TableSector> _groupTables(List<RestaurantTableModel> tables) {
    final bySector = <String, List<RestaurantTableModel>>{};
    for (final table in tables) {
      bySector.putIfAbsent(table.mapId, () => []).add(table);
    }

    const preferredOrder = ['salon-principal', 'terraza', 'segundo-piso'];
    final sectorIds = <String>[
      ...preferredOrder.where(bySector.containsKey),
      ...bySector.keys.where((id) => !preferredOrder.contains(id)),
    ];

    return [
      for (final id in sectorIds)
        _TableSector(
          name: bySector[id]!.first.mapName,
          tables: (bySector[id]!..sort((a, b) => a.id.compareTo(b.id))),
        ),
    ];
  }

  Widget _sectorHeader(BuildContext context, String title, String range) {
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
    required List<RestaurantTableModel> tables,
    required int columns,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate((context, index) {
          final table = tables[index];
          return _TableCard(
            table: table,
            occupied: store.isOccupied(table.number),
            itemCount: store.itemCountFor(table.number),
            total: store.totalFor(table.number),
            remoteOrder: store.remoteOrderFor(table.number),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(tableNumber: table.number),
              ),
            ),
          );
        }, childCount: tables.length),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.02,
        ),
      ),
    );
  }
}

class _TableSector {
  const _TableSector({required this.name, required this.tables});

  final String name;
  final List<RestaurantTableModel> tables;
}

class _TableCard extends StatelessWidget {
  const _TableCard({
    required this.table,
    required this.occupied,
    required this.itemCount,
    required this.total,
    this.remoteOrder,
    required this.onTap,
  });

  final RestaurantTableModel table;
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
                    table.displayName,
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
                        : '${table.chairs} personas',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: occupied ? color : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    table.location,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant,
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

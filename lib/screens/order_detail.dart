import 'package:flutter/material.dart';
import 'package:polleria_movil/data/restaurant_store.dart';
import 'package:polleria_movil/screens/ticket_print_screen.dart';
import 'package:polleria_movil/widgets/theme_toggle_button.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.tableNumber});

  final String tableNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final store = RestaurantStore.instance;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Pedido · ${store.displayNameFor(tableNumber)}'),
        actions: const [ThemeToggleButton()],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: IgnorePointer(
              child: Opacity(
                opacity: isDark ? 0.08 : 0.05,
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
            builder: (context, _) {
              final items = store.itemsFor(tableNumber);
              final remoteOrder = store.remoteOrderFor(tableNumber);
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Pedido actual',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _TableStatus(occupied: store.isOccupied(tableNumber)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${store.itemCountFor(tableNumber)} productos',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (remoteOrder != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2C2422)
                              : const Color(0xFFFFF4EE),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.cloud_done_outlined,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pedido #${remoteOrder.id} · '
                                'Estado: ${remoteOrder.status ?? 'Activo'} · '
                                'Cliente: ${remoteOrder.customerName ?? store.displayNameFor(tableNumber)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _showMenu(context, store),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar productos'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        backgroundColor: colorScheme.surface,
                        side: BorderSide(color: colorScheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (items.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            'Aún no hay productos en esta mesa.',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              Divider(height: 1, color: theme.dividerColor),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              isThreeLine:
                                  item.product.description != null &&
                                  item.product.description!.trim().isNotEmpty,
                              leading: CircleAvatar(
                                backgroundColor: colorScheme.primaryContainer,
                                foregroundColor: colorScheme.onPrimaryContainer,
                                child: Text('${item.quantity}×'),
                              ),
                              title: Text(
                                item.product.name,
                                softWrap: true,
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item.product.description != null &&
                                      item.product.description!
                                          .trim()
                                          .isNotEmpty) ...[
                                    Text(
                                      item.product.description!,
                                      softWrap: true,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                  ],
                                  Text(
                                    '${_money(item.product.price)} c/u',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _money(item.subtotal),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  IconButton(
                                    tooltip: 'Quitar una unidad',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => store.removeOne(
                                      tableNumber,
                                      item.product.id,
                                    ),
                                    icon: Icon(
                                      Icons.remove_circle_outline,
                                      color: colorScheme.error,
                                      size: 22,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Agregar otra unidad',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => store.addProduct(
                                      tableNumber,
                                      item.product,
                                    ),
                                    icon: Icon(
                                      Icons.add_circle_outline,
                                      color: colorScheme.primary,
                                      size: 22,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final hasOrder = store.isOccupied(tableNumber);
          return SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: ColoredBox(
              color: theme.scaffoldBackgroundColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        _money(store.totalFor(tableNumber)),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: hasOrder
                              ? () => _showKitchenOrder(
                                  context,
                                  store.itemsFor(tableNumber),
                                )
                              : null,
                          icon: const Icon(Icons.soup_kitchen_outlined),
                          label: const Text('Comanda cocina'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                            side: BorderSide(
                              color: hasOrder
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant.withValues(
                                      alpha: 0.3,
                                    ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: hasOrder
                              ? () async {
                                  final order = await store
                                      .completeOrderForTicket(tableNumber);
                                  if (order != null && context.mounted) {
                                    _showTicket(context, order);
                                  }
                                }
                              : null,
                          icon: const Icon(Icons.receipt_long),
                          label: const Text('Generar ticket'),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showMenu(BuildContext context, RestaurantStore store) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor:
          theme.bottomSheetTheme.backgroundColor ?? colorScheme.surface,
      builder: (context) {
        MenuCategory? selectedCategory;
        String searchQuery = '';
        String? lastActionMessage;
        final Set<String> expandedProductIds = {};

        return StatefulBuilder(
          builder: (context, setSheetState) {
            int getQty(String productId) {
              final currentItems = store.itemsFor(tableNumber);
              for (final it in currentItems) {
                if (it.product.id == productId) return it.quantity;
              }
              return 0;
            }

            final allProducts = RestaurantStore.menu;
            final products = allProducts.where((product) {
              if (selectedCategory != null &&
                  product.category != selectedCategory) {
                return false;
              }
              if (searchQuery.isNotEmpty) {
                final query = searchQuery.toLowerCase();
                final nameMatches = product.name.toLowerCase().contains(query);
                final descMatches =
                    product.description?.toLowerCase().contains(query) ?? false;
                return nameMatches || descMatches;
              }
              return true;
            }).toList();

            return SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.85,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Menú · ${store.displayNameFor(tableNumber)}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${allProducts.length} producto(s) en carta',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Actualizar menú',
                          onPressed: store.isLoadingMenu
                              ? null
                              : () async {
                                  await store.loadMenuFromApi();
                                  setSheetState(() {});
                                },
                          icon: store.isLoadingMenu
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(Icons.sync, color: colorScheme.onSurface),
                        ),
                        IconButton(
                          tooltip: 'Cerrar',
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: colorScheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar plato o bebida...',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setSheetState(() => searchQuery = val.trim());
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                    child: DropdownButtonFormField<MenuCategory?>(
                      initialValue: selectedCategory,
                      dropdownColor: colorScheme.surface,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Categoría',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(
                          Icons.category_outlined,
                          color: colorScheme.primary,
                        ),
                      ),
                      items: [
                        DropdownMenuItem<MenuCategory?>(
                          value: null,
                          child: Text(
                            'Todas las categorías (${allProducts.length})',
                          ),
                        ),
                        ...MenuCategory.values.map((category) {
                          final count = allProducts
                              .where((p) => p.category == category)
                              .length;
                          return DropdownMenuItem<MenuCategory?>(
                            value: category,
                            child: Text('${category.label} ($count)'),
                          );
                        }),
                      ],
                      onChanged: (category) {
                        setSheetState(() => selectedCategory = category);
                      },
                    ),
                  ),
                  if (lastActionMessage != null)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E3A2B)
                            : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF48B383)
                              : Colors.green,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: isDark
                                ? const Color(0xFF48B383)
                                : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              lastActionMessage!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1B5E20),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Divider(height: 1, color: theme.dividerColor),
                  if (store.isLoadingMenu)
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text('Cargando productos...'),
                          ],
                        ),
                      ),
                    )
                  else if (products.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No se encontraron productos',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: products.length,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final img = product.rawProduct?.image;
                          final hasNetImg =
                              img != null && img.startsWith('http');
                          final qty = getQty(product.id);
                          final isAdded = qty > 0;

                          final leadingWidget = hasNetImg
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    img,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          product.icon,
                                          color: colorScheme.primary,
                                        ),
                                  ),
                                )
                              : CircleAvatar(
                                  backgroundColor: colorScheme.primaryContainer
                                      .withValues(alpha: 0.4),
                                  child: Icon(
                                    product.icon,
                                    color: colorScheme.primary,
                                  ),
                                );

                          final isExpanded = expandedProductIds.contains(
                            product.id,
                          );

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            elevation: isAdded ? 1.5 : 0,
                            color: isAdded
                                ? (isDark
                                      ? colorScheme.primary.withValues(
                                          alpha: 0.15,
                                        )
                                      : colorScheme.primary.withValues(
                                          alpha: 0.08,
                                        ))
                                : theme.cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isAdded
                                    ? colorScheme.primary
                                    : theme.dividerColor,
                                width: isAdded ? 1.8 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Badge(
                                    isLabelVisible: isAdded,
                                    label: Text(
                                      '$qty',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    backgroundColor: colorScheme.primary,
                                    child: leadingWidget,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                product.name,
                                                style: TextStyle(
                                                  color: colorScheme.onSurface,
                                                  fontWeight: isAdded
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            if (product.rawProduct?.isOnSale ==
                                                true) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.redAccent,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'OFERTA',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (product.description != null &&
                                            product.description!
                                                .trim()
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          InkWell(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            onTap: () {
                                              setSheetState(() {
                                                if (isExpanded) {
                                                  expandedProductIds.remove(
                                                    product.id,
                                                  );
                                                } else {
                                                  expandedProductIds.add(
                                                    product.id,
                                                  );
                                                }
                                              });
                                            },
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.description!,
                                                  maxLines: isExpanded
                                                      ? null
                                                      : 2,
                                                  overflow: isExpanded
                                                      ? TextOverflow.visible
                                                      : TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                    height: 1.3,
                                                  ),
                                                ),
                                                if (product
                                                        .description!
                                                        .length >
                                                    40)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 2,
                                                        ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          isExpanded
                                                              ? 'Ver menos'
                                                              : 'Ver más',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: colorScheme
                                                                .primary,
                                                          ),
                                                        ),
                                                        Icon(
                                                          isExpanded
                                                              ? Icons
                                                                    .keyboard_arrow_up
                                                              : Icons
                                                                    .keyboard_arrow_down,
                                                          size: 14,
                                                          color: colorScheme
                                                              .primary,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  _money(product.price),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: colorScheme.primary,
                                                  ),
                                                ),
                                                if (product.rawProduct !=
                                                        null &&
                                                    product
                                                            .rawProduct!
                                                            .basePrice >
                                                        product.price)
                                                  Text(
                                                    _money(
                                                      product
                                                          .rawProduct!
                                                          .basePrice,
                                                    ),
                                                    style: TextStyle(
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                      fontSize: 11,
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const Spacer(),
                                            if (isAdded)
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? const Color(0xFF382C28)
                                                      : const Color(0xFFF5EBE6),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: colorScheme.primary
                                                        .withValues(alpha: 0.5),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      iconSize: 18,
                                                      tooltip:
                                                          'Quitar una unidad',
                                                      onPressed: () {
                                                        setSheetState(() {
                                                          store.removeOne(
                                                            tableNumber,
                                                            product.id,
                                                          );
                                                          final newQty = getQty(
                                                            product.id,
                                                          );
                                                          if (newQty > 0) {
                                                            lastActionMessage =
                                                                '${product.name} reducido a $newQty en ${store.displayNameFor(tableNumber)}';
                                                          } else {
                                                            lastActionMessage =
                                                                '${product.name} retirado de ${store.displayNameFor(tableNumber)}';
                                                          }
                                                        });
                                                      },
                                                      icon: Icon(
                                                        Icons.remove,
                                                        color:
                                                            colorScheme.error,
                                                      ),
                                                    ),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 3,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            colorScheme.primary,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        '$qty',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      iconSize: 18,
                                                      tooltip:
                                                          'Agregar otra unidad',
                                                      onPressed: () {
                                                        setSheetState(() {
                                                          store.addProduct(
                                                            tableNumber,
                                                            product,
                                                          );
                                                          final newQty = getQty(
                                                            product.id,
                                                          );
                                                          lastActionMessage =
                                                              '${product.name} ×$newQty en ${store.displayNameFor(tableNumber)}';
                                                        });
                                                      },
                                                      icon: Icon(
                                                        Icons.add,
                                                        color:
                                                            colorScheme.primary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            else
                                              FilledButton.tonalIcon(
                                                style: FilledButton.styleFrom(
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  setSheetState(() {
                                                    store.addProduct(
                                                      tableNumber,
                                                      product,
                                                    );
                                                    final newQty = getQty(
                                                      product.id,
                                                    );
                                                    lastActionMessage =
                                                        '${product.name} ×$newQty agregado a ${store.displayNameFor(tableNumber)}';
                                                  });
                                                },
                                                icon: const Icon(
                                                  Icons.add,
                                                  size: 16,
                                                ),
                                                label: const Text('Agregar'),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      border: Border(
                        top: BorderSide(color: theme.dividerColor),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${store.itemCountFor(tableNumber)} productos en ${store.displayNameFor(tableNumber)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'Total: ${_money(store.totalFor(tableNumber))}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: () => Navigator.pop(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.check, size: 18),
                            label: Text(
                              'Listo (${store.itemCountFor(tableNumber)})',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showTicket(BuildContext context, CompletedOrder order) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = order.completedAt;

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor:
            theme.dialogTheme.backgroundColor ?? colorScheme.surface,
        title: Row(
          children: [
            Icon(Icons.receipt_long, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Ticket de pedido',
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text(
                    'POLLERÍA EL GIGANTE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                Divider(color: theme.dividerColor),
                Text(
                  'Ticket: ${order.ticketNumber}',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                Text(
                  'Mesa: ${order.tableNumber}',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                Text(
                  'Fecha: ${_dateTime(now)}',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                Divider(color: theme.dividerColor),
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
                          _money(item.subtotal),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(color: theme.dividerColor),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'TOTAL',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      _money(order.total),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    '¡Gracias por su visita!',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
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

  Future<void> _showKitchenOrder(BuildContext context, List<OrderItem> items) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    final commandNumber = 'COM-M$tableNumber-${now.millisecondsSinceEpoch}';

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            theme.dialogTheme.backgroundColor ?? colorScheme.surface,
        title: Row(
          children: [
            Icon(Icons.soup_kitchen_outlined, color: colorScheme.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Comanda para cocina',
                style: TextStyle(color: colorScheme.onSurface),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text(
                    'POLLERÍA EL GIGANTE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                Divider(color: theme.dividerColor),
                Text(
                  'Comanda: $commandNumber',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                Text(
                  RestaurantStore.instance
                      .displayNameFor(tableNumber)
                      .toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Hora: ${_dateTime(now)}',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                Divider(color: theme.dividerColor),
                Text(
                  'DETALLE DEL PEDIDO',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 48,
                          child: Text(
                            '${item.quantity} ×',
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
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(color: theme.dividerColor),
                Center(
                  child: Text(
                    'Preparar pedido',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _TableStatus extends StatelessWidget {
  const _TableStatus({required this.occupied});

  final bool occupied;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final color = occupied
        ? (isDark ? const Color(0xFFE58F75) : const Color(0xFF914F3A))
        : (isDark ? const Color(0xFF48B383) : const Color(0xFF168C5B));

    final bgColor = occupied
        ? (isDark ? const Color(0xFF3D231B) : const Color(0xFFF3DCD3))
        : (isDark ? const Color(0xFF1B2E24) : const Color(0xFFE7F2E9));

    return Chip(
      backgroundColor: bgColor,
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      avatar: Icon(
        occupied ? Icons.circle : Icons.check_circle,
        size: 16,
        color: color,
      ),
      label: Text(occupied ? 'OCUPADO' : 'LIBRE'),
    );
  }
}

String _money(double amount) => 'S/ ${amount.toStringAsFixed(2)}';

String _dateTime(DateTime dateTime) {
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$day/$month/${dateTime.year} $hour:$minute';
}

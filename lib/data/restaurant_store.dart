import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:polleria_movil/api/api.dart';
import 'package:polleria_movil/data/app_storage.dart';

enum MenuCategory {
  polloALaBrasa('Pollo a la brasa'),
  parrillas('Parrillas'),
  ensaladas('Ensaladas'),
  chichasYGaseosas('Chichas y gaseosas'),
  guarniciones('Guarniciones');

  const MenuCategory(this.label);

  final String label;

  static MenuCategory fromApi(int? id, String? name, {String? productName}) {
    final search = '${name ?? ''} ${productName ?? ''}'.toLowerCase();
    if (search.contains('parrilla')) return MenuCategory.parrillas;
    if (search.contains('ensalada')) return MenuCategory.ensaladas;
    if (search.contains('bebida') ||
        search.contains('gaseosa') ||
        search.contains('chicha') ||
        search.contains('agua') ||
        search.contains('refresco') ||
        search.contains('inka') ||
        search.contains('coca')) {
      return MenuCategory.chichasYGaseosas;
    }
    if (search.contains('guarnicion') ||
        search.contains('papa') ||
        search.contains('arroz') ||
        search.contains('porcion') ||
        search.contains('complemento')) {
      return MenuCategory.guarniciones;
    }
    if (search.contains('pollo')) return MenuCategory.polloALaBrasa;

    if (id != null) {
      switch (id) {
        case 1:
          return MenuCategory.polloALaBrasa;
        case 2:
          return MenuCategory.parrillas;
        case 3:
          return MenuCategory.ensaladas;
        case 4:
          return MenuCategory.chichasYGaseosas;
        case 5:
          return MenuCategory.guarniciones;
      }
    }
    return MenuCategory.polloALaBrasa;
  }
}

class MenuProduct {
  const MenuProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
    required this.category,
    this.description,
    this.rawProduct,
  });

  final String id;
  final String name;
  final double price;
  final IconData icon;
  final MenuCategory category;
  final String? description;
  final ProductModel? rawProduct;

  factory MenuProduct.fromProductModel(ProductModel model) {
    final cat = MenuCategory.fromApi(
      model.categoryId,
      model.category?.name,
      productName: model.name,
    );
    IconData icon;
    switch (cat) {
      case MenuCategory.polloALaBrasa:
        icon = Icons.restaurant;
        break;
      case MenuCategory.parrillas:
        icon = Icons.outdoor_grill;
        break;
      case MenuCategory.ensaladas:
        icon = Icons.eco;
        break;
      case MenuCategory.chichasYGaseosas:
        icon = Icons.local_drink;
        break;
      case MenuCategory.guarniciones:
        icon = Icons.fastfood;
        break;
    }

    return MenuProduct(
      id: model.id.toString(),
      name: model.name,
      price: model.salePrice > 0 ? model.salePrice : model.basePrice,
      icon: icon,
      category: cat,
      description: model.description,
      rawProduct: model,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'category': category.name,
    'description': description,
  };

  factory MenuProduct.fromJson(Map<String, dynamic> json) {
    final catName = json['category'] as String?;
    final cat = MenuCategory.values.firstWhere(
      (c) => c.name == catName,
      orElse: () => MenuCategory.polloALaBrasa,
    );
    IconData icon;
    switch (cat) {
      case MenuCategory.polloALaBrasa:
        icon = Icons.restaurant;
        break;
      case MenuCategory.parrillas:
        icon = Icons.outdoor_grill;
        break;
      case MenuCategory.ensaladas:
        icon = Icons.eco;
        break;
      case MenuCategory.chichasYGaseosas:
        icon = Icons.local_drink;
        break;
      case MenuCategory.guarniciones:
        icon = Icons.fastfood;
        break;
    }
    return MenuProduct(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      icon: icon,
      category: cat,
      description: json['description']?.toString(),
    );
  }
}

class OrderItem {
  OrderItem({required this.product, this.quantity = 1});

  final MenuProduct product;
  int quantity;

  double get subtotal => product.price * quantity;

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    product: MenuProduct.fromJson(Map<String, dynamic>.from(json['product'] as Map)),
    quantity: json['quantity'] as int? ?? 1,
  );
}

class CompletedOrder {
  const CompletedOrder({
    required this.ticketNumber,
    required this.tableNumber,
    required this.items,
    required this.completedAt,
    this.remoteOrderId,
  });

  final String ticketNumber;
  final int tableNumber;
  final List<OrderItem> items;
  final DateTime completedAt;
  final int? remoteOrderId;

  int get itemCount => items.fold(0, (count, item) => count + item.quantity);

  double get total => items.fold(0, (sum, item) => sum + item.subtotal);
}

class RestaurantStore extends ChangeNotifier {
  RestaurantStore._() {
    _restoreMenuFromHive();
    _restoreTableOrdersFromHive();
  }

  void _restoreMenuFromHive() {
    final cached = AppStorage.getCachedMenu();
    if (cached != null && cached.isNotEmpty) {
      try {
        _menu = cached.map(MenuProduct.fromJson).toList();
        return;
      } catch (e) {
        developer.log('Error restaurando menú de Hive: $e');
      }
    }
    _menu = List.from(defaultMenu);
  }

  void _restoreTableOrdersFromHive() {
    final saved = AppStorage.getTableOrders();
    if (saved != null && saved.isNotEmpty) {
      try {
        saved.forEach((table, itemsJson) {
          _orders[table] = itemsJson.map(OrderItem.fromJson).toList();
        });
      } catch (e) {
        developer.log('Error restaurando pedidos de mesas de Hive: $e');
      }
    }
  }

  void _persistTableOrdersToHive() {
    final map = <int, List<Map<String, dynamic>>>{};
    _orders.forEach((table, items) {
      if (items.isNotEmpty) {
        map[table] = items.map((i) => i.toJson()).toList();
      }
    });
    AppStorage.setTableOrders(map);
  }

  static final RestaurantStore instance = RestaurantStore._();

  final ProductsService _productsService = ProductsService();
  final OrdersService _ordersService = OrdersService();

  static const defaultMenu = <MenuProduct>[
    MenuProduct(
      id: '1',
      name: '1/4 de pollo',
      price: 12,
      icon: Icons.restaurant,
      category: MenuCategory.polloALaBrasa,
    ),
    MenuProduct(
      id: '2',
      name: '1/2 pollo',
      price: 24,
      icon: Icons.restaurant,
      category: MenuCategory.polloALaBrasa,
    ),
    MenuProduct(
      id: '3',
      name: 'Pollo entero',
      price: 48,
      icon: Icons.restaurant,
      category: MenuCategory.polloALaBrasa,
    ),
    MenuProduct(
      id: '4',
      name: '1/4 de pollo a la brasa a lo pobre',
      price: 18,
      icon: Icons.restaurant,
      category: MenuCategory.polloALaBrasa,
    ),
    MenuProduct(
      id: '5',
      name: '1/2 parrilla',
      price: 12,
      icon: Icons.outdoor_grill,
      category: MenuCategory.parrillas,
    ),
    MenuProduct(
      id: '6',
      name: 'Parrilla',
      price: 18,
      icon: Icons.outdoor_grill,
      category: MenuCategory.parrillas,
    ),
    MenuProduct(
      id: '7',
      name: 'Porción de papas fritas',
      price: 8,
      icon: Icons.fastfood,
      category: MenuCategory.guarniciones,
    ),
    MenuProduct(
      id: '8',
      name: 'Ensalada',
      price: 7,
      icon: Icons.eco,
      category: MenuCategory.ensaladas,
    ),
    MenuProduct(
      id: '9',
      name: 'Gaseosa 1.5 L',
      price: 10,
      icon: Icons.local_drink,
      category: MenuCategory.chichasYGaseosas,
    ),
    MenuProduct(
      id: '10',
      name: 'Chicha morada 1 L',
      price: 9,
      icon: Icons.local_cafe,
      category: MenuCategory.chichasYGaseosas,
    ),
  ];

  static List<MenuProduct> get menu => instance._menu;

  void setCustomMenu(List<MenuProduct> items) {
    _menu = List.from(items);
    notifyListeners();
  }

  void resetMenu() {
    _menu = List.from(defaultMenu);
    notifyListeners();
  }

  List<MenuProduct> _menu = [];
  bool _isLoadingMenu = false;
  bool get isLoadingMenu => _isLoadingMenu;

  bool _isLoadingOrders = false;
  bool get isLoadingOrders => _isLoadingOrders;

  String? _lastOrdersError;
  String? get lastOrdersError => _lastOrdersError;

  String? _lastMenuError;
  String? get lastMenuError => _lastMenuError;

  final Map<int, OrderResponse> _remoteOrders = {};
  OrderResponse? remoteOrderFor(int tableNumber) => _remoteOrders[tableNumber];

  final Map<int, List<OrderItem>> _orders = {};
  final Set<int> _attendedTables = {};
  final List<CompletedOrder> _completedOrders = [];

  List<CompletedOrder> get completedOrders =>
      List.unmodifiable(_completedOrders.reversed);

  CompletedOrder? completedOrder(String ticketNumber) {
    for (final order in _completedOrders) {
      if (order.ticketNumber == ticketNumber) return order;
    }
    return null;
  }

  List<OrderItem> itemsFor(int tableNumber) =>
      List.unmodifiable(_orders[tableNumber] ?? const <OrderItem>[]);

  List<int> tablesWithOrders({required bool attended}) {
    final tables = _orders.keys.where((table) {
      final hasItems = _orders[table]!.isNotEmpty;
      return hasItems && _attendedTables.contains(table) == attended;
    }).toList()..sort();
    return tables;
  }

  bool isOccupied(int tableNumber) =>
      _orders[tableNumber]?.isNotEmpty ?? false;

  double totalFor(int tableNumber) =>
      (_orders[tableNumber] ?? const <OrderItem>[]).fold<double>(
        0,
        (total, item) => total + item.subtotal,
      );

  int itemCountFor(int tableNumber) =>
      (_orders[tableNumber] ?? const <OrderItem>[]).fold<int>(
        0,
        (count, item) => count + item.quantity,
      );

  void addProduct(int tableNumber, MenuProduct product) {
    final items = _orders.putIfAbsent(tableNumber, () => []);
    final existingIndex = items.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (existingIndex == -1) {
      items.add(OrderItem(product: product));
    } else {
      items[existingIndex].quantity++;
    }
    _attendedTables.remove(tableNumber);
    _persistTableOrdersToHive();
    notifyListeners();
  }

  void removeOne(int tableNumber, String productId) {
    final items = _orders[tableNumber];
    if (items == null) return;
    final index = items.indexWhere((item) => item.product.id == productId);
    if (index == -1) return;
    if (items[index].quantity > 1) {
      items[index].quantity--;
    } else {
      items.removeAt(index);
    }
    if (items.isEmpty) {
      _orders.remove(tableNumber);
      _attendedTables.remove(tableNumber);
    }
    _persistTableOrdersToHive();
    notifyListeners();
  }

  void clearTable(int tableNumber) {
    _orders.remove(tableNumber);
    _attendedTables.remove(tableNumber);
    _remoteOrders.remove(tableNumber);
    _persistTableOrdersToHive();
    notifyListeners();
  }

  void markAttended(int tableNumber) {
    if (isOccupied(tableNumber)) {
      _attendedTables.add(tableNumber);
      notifyListeners();
    }
  }

  Future<void> loadMenuFromApi() async {
    _isLoadingMenu = true;
    _lastMenuError = null;
    notifyListeners();
    try {
      final apiProducts = await _productsService.getProducts();
      if (apiProducts.isNotEmpty) {
        _menu = apiProducts.map(MenuProduct.fromProductModel).toList();
        AppStorage.setCachedMenu(_menu.map((p) => p.toJson()).toList());
      }
    } catch (e) {
      _lastMenuError = e.toString();
      developer.log('No se pudo cargar menú desde la API, verificando Hive: $e');
      final cached = AppStorage.getCachedMenu();
      if (cached != null && cached.isNotEmpty && _menu.isEmpty) {
        _menu = cached.map(MenuProduct.fromJson).toList();
      }
    } finally {
      _isLoadingMenu = false;
      notifyListeners();
    }
  }

  Future<void> loadOrdersFromApi() async {
    _isLoadingOrders = true;
    _lastOrdersError = null;
    notifyListeners();
    try {
      final orders = await _ordersService.getOrders();
      _remoteOrders.clear();

      for (final order in orders) {
        final tableStr = order.tableNumber;
        if (tableStr == null || tableStr.trim().isEmpty) continue;
        final tableNum = int.tryParse(tableStr.trim());
        if (tableNum == null || tableNum < 1 || tableNum > 18) continue;

        final statusLower = (order.status ?? '').toLowerCase();
        final isCancelled = statusLower.contains('anulado') || statusLower.contains('cancel');
        if (isCancelled) continue;

        _remoteOrders[tableNum] = order;

        final orderItems = <OrderItem>[];
        for (final item in order.items) {
          final existing = _menu.firstWhere(
            (p) =>
                p.name.trim().toLowerCase() == item.productName.trim().toLowerCase() ||
                p.id == item.id.toString(),
            orElse: () => MenuProduct(
              id: item.id.toString(),
              name: item.productName,
              price: item.price,
              icon: Icons.restaurant,
              category: MenuCategory.fromApi(null, null, productName: item.productName),
            ),
          );
          orderItems.add(OrderItem(product: existing, quantity: item.quantity));
        }

        if (orderItems.isNotEmpty) {
          _orders[tableNum] = orderItems;
        }

        final isDelivered = statusLower.contains('entregado') ||
            statusLower.contains('delivered') ||
            statusLower.contains('complet');
        if (isDelivered) {
          _attendedTables.add(tableNum);
        } else {
          _attendedTables.remove(tableNum);
        }
      }
    } catch (e) {
      _lastOrdersError = e.toString();
      developer.log('Error al sincronizar pedidos desde API: $e');
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
  }

  Future<void> loadAllFromApi() async {
    await Future.wait([
      loadMenuFromApi(),
      loadOrdersFromApi(),
    ]);
  }

  Future<CompletedOrder?> completeOrderForTicket(
    int tableNumber, {
    String? customerName,
    String? documentNumber,
    String? documentType,
  }) async {
    final currentItems = _orders[tableNumber];
    if (currentItems == null || currentItems.isEmpty) return null;

    final completedAt = DateTime.now();
    int? remoteId;

    // Send order to API /api/Pedidos
    try {
      final details = currentItems.map((item) {
        final prodId = int.tryParse(item.product.id) ?? 1;
        return OrderDetailRequest(
          productId: prodId,
          quantity: item.quantity,
        );
      }).toList();

      final request = OrderRequest(
        tableNumber: tableNumber.toString(),
        isPos: true,
        userId: 1,
        customerName: customerName ?? 'Mesa $tableNumber',
        documentNumber: documentNumber,
        documentType: documentType,
        details: details,
      );

      final response = await _ordersService.createOrder(request);
      if (response is Map<String, dynamic> && response['id'] is int) {
        remoteId = response['id'] as int;
      }
    } catch (e) {
      developer.log('No se pudo registrar pedido en API /api/Pedidos: $e');
    }

    final order = CompletedOrder(
      ticketNumber: 'T-$tableNumber-${completedAt.microsecondsSinceEpoch}',
      tableNumber: tableNumber,
      items: List.unmodifiable(
        currentItems.map(
          (item) => OrderItem(
            product: item.product,
            quantity: item.quantity,
          ),
        ),
      ),
      completedAt: completedAt,
      remoteOrderId: remoteId,
    );
    _completedOrders.add(order);
    _orders.remove(tableNumber);
    _attendedTables.remove(tableNumber);
    _persistTableOrdersToHive();
    notifyListeners();
    return order;
  }
}

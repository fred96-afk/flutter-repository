class OrderDetailRequest {
  const OrderDetailRequest({
    required this.productId,
    this.sideId,
    required this.quantity,
  });

  final int productId;
  final int? sideId;
  final int quantity;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    if (sideId != null) 'sideId': sideId,
    'quantity': quantity,
  };

  factory OrderDetailRequest.fromJson(Map<String, dynamic> json) => OrderDetailRequest(
    productId: json['productId'] is int ? json['productId'] as int : int.tryParse(json['productId']?.toString() ?? '0') ?? 0,
    sideId: json['sideId'] is int ? json['sideId'] as int : int.tryParse(json['sideId']?.toString() ?? ''),
    quantity: json['quantity'] is int ? json['quantity'] as int : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
  );
}

class OrderRequest {
  const OrderRequest({
    this.clientId,
    this.userId = 1,
    this.deliveryUserId,
    this.details,
    this.isPos = true,
    this.customerName,
    this.documentNumber,
    this.documentType,
    this.customerEmail,
    this.customerAddress,
    this.customerPhone,
    this.isPickup = false,
    this.tableNumber,
  });

  final int? clientId;
  final int userId;
  final int? deliveryUserId;
  final List<OrderDetailRequest>? details;
  final bool isPos;
  final String? customerName;
  final String? documentNumber;
  final String? documentType;
  final String? customerEmail;
  final String? customerAddress;
  final String? customerPhone;
  final bool isPickup;
  final String? tableNumber;

  Map<String, dynamic> toJson() => {
    if (clientId != null) 'clientId': clientId,
    'userId': userId,
    if (deliveryUserId != null) 'deliveryUserId': deliveryUserId,
    if (details != null) 'details': details!.map((d) => d.toJson()).toList(),
    'isPos': isPos,
    if (customerName != null) 'customerName': customerName,
    if (documentNumber != null) 'documentNumber': documentNumber,
    if (documentType != null) 'documentType': documentType,
    if (customerEmail != null) 'customerEmail': customerEmail,
    if (customerAddress != null) 'customerAddress': customerAddress,
    if (customerPhone != null) 'customerPhone': customerPhone,
    'isPickup': isPickup,
    if (tableNumber != null) 'tableNumber': tableNumber,
  };
}

class StatusUpdateRequest {
  const StatusUpdateRequest({
    this.status,
    this.valor,
  });

  final String? status;
  final String? valor;

  Map<String, dynamic> toJson() => {
    if (status != null) 'status': status,
    if (valor != null) 'valor': valor,
  };
}

class AcceptDeliveryRequest {
  const AcceptDeliveryRequest({required this.deliveryUserId});

  final int deliveryUserId;

  Map<String, dynamic> toJson() => {
    'deliveryUserId': deliveryUserId,
  };
}

class OrderResponseItem {
  const OrderResponseItem({
    required this.id,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  final int id;
  final String productName;
  final double price;
  final int quantity;
  final double subtotal;

  factory OrderResponseItem.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic val) {
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    final q = parseInt(json['quantity'] ?? json['cantidad'] ?? 1);
    final p = parseDouble(json['unitPrice'] ?? json['price'] ?? json['precio'] ?? 0.0);
    final s = parseDouble(json['subtotal'] ?? (p * q));

    return OrderResponseItem(
      id: parseInt(json['productId'] ?? json['id'] ?? 0),
      productName: json['productName']?.toString() ?? json['name']?.toString() ?? 'Producto',
      price: p,
      quantity: q,
      subtotal: s,
    );
  }
}

class OrderResponse {
  const OrderResponse({
    required this.id,
    this.tableNumber,
    this.customerName,
    this.status,
    this.paymentStatus,
    this.total = 0.0,
    this.items = const [],
    this.createdAt,
    this.isPos = false,
    this.type,
  });

  final int id;
  final String? tableNumber;
  final String? customerName;
  final String? status;
  final String? paymentStatus;
  final double total;
  final List<OrderResponseItem> items;
  final DateTime? createdAt;
  final bool isPos;
  final String? type;

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic val) {
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    final rawDetails = json['details'] ?? json['items'] ?? json['detalles'];
    final itemsList = <OrderResponseItem>[];
    if (rawDetails is List) {
      for (final it in rawDetails) {
        if (it is Map<String, dynamic>) {
          itemsList.add(OrderResponseItem.fromJson(it));
        }
      }
    }

    DateTime? date;
    if (json['orderDate'] != null) {
      date = DateTime.tryParse(json['orderDate'].toString());
    } else if (json['createdAt'] != null) {
      date = DateTime.tryParse(json['createdAt'].toString());
    } else if (json['fecha'] != null) {
      date = DateTime.tryParse(json['fecha'].toString());
    }

    return OrderResponse(
      id: parseInt(json['id'] ?? 0),
      tableNumber: json['tableNumber']?.toString() ?? json['mesa']?.toString(),
      customerName: json['customerName']?.toString() ?? json['cliente']?.toString(),
      status: json['status']?.toString() ?? json['estado']?.toString(),
      paymentStatus: json['paymentStatus']?.toString() ?? json['estadoPago']?.toString(),
      total: parseDouble(json['totalAmount'] ?? json['total'] ?? json['montoTotal'] ?? 0.0),
      items: itemsList,
      createdAt: date ?? DateTime.now(),
      isPos: json['isPos'] == true,
      type: json['type']?.toString() ?? json['tipo']?.toString(),
    );
  }
}

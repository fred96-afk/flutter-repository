class RestaurantTableModel {
  const RestaurantTableModel({
    required this.id,
    required this.number,
    required this.name,
    this.chairs = 4,
    this.location = 'Salón Principal',
    this.mapId = 'salon-principal',
    this.shape = 'square',
    this.x = 0.0,
    this.y = 0.0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String number;
  final String name;
  final int chairs;
  final String location;
  final String mapId;
  final String shape; // 'square', 'round', 'rectangle'
  final double x;
  final double y;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Nombre para mostrar en pantalla (ej. "Mesa 1", "Mesa Terraza 1", "Mesa Presidencial").
  String get displayName => name.isNotEmpty ? name : 'Mesa $number';

  /// Nombre de piso o sector legible para agrupar visualmente.
  String get sectorName {
    final lower = (location + mapId).toLowerCase();
    if (lower.contains('terraza')) return 'Terraza';
    if (lower.contains('segundo') || lower.contains('vip') || lower.contains('piso 2') || lower.contains('balcón')) {
      return 'Segundo Piso / VIP';
    }
    return 'Salón Principal';
  }

  /// Código o número entero de respaldo para rutas y órdenes.
  int get tableNumberInt {
    final parsed = int.tryParse(number.replaceAll(RegExp(r'[^0-9]'), ''));
    if (parsed != null && parsed > 0) return parsed;
    return id;
  }

  factory RestaurantTableModel.fromJson(Map<String, dynamic> json) {
    return RestaurantTableModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      number: json['number']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Mesa ${json['number'] ?? json['id'] ?? ''}',
      chairs: json['chairs'] is int
          ? json['chairs'] as int
          : int.tryParse(json['chairs']?.toString() ?? '4') ?? 4,
      location: json['location']?.toString() ?? 'Salón Principal',
      mapId: json['mapId']?.toString() ?? 'salon-principal',
      shape: json['shape']?.toString() ?? 'square',
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] == null || json['isActive'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'name': name,
    'chairs': chairs,
    'location': location,
    'mapId': mapId,
    'shape': shape,
    'x': x,
    'y': y,
    'isActive': isActive,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  RestaurantTableModel copyWith({
    int? id,
    String? number,
    String? name,
    int? chairs,
    String? location,
    String? mapId,
    String? shape,
    double? x,
    double? y,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RestaurantTableModel(
      id: id ?? this.id,
      number: number ?? this.number,
      name: name ?? this.name,
      chairs: chairs ?? this.chairs,
      location: location ?? this.location,
      mapId: mapId ?? this.mapId,
      shape: shape ?? this.shape,
      x: x ?? this.x,
      y: y ?? this.y,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

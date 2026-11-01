class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.name,
    this.code,
    this.description,
  });

  final dynamic id;
  final String name;
  final String? code;
  final String? description;

  factory CatalogItem.fromJson(dynamic json) {
    if (json is String) {
      return CatalogItem(id: json, name: json);
    }
    if (json is Map<String, dynamic>) {
      return CatalogItem(
        id: json['id'] ?? json['Id'] ?? json['codigo'] ?? '',
        name: json['name']?.toString() ?? json['nombre']?.toString() ?? json['descripcion']?.toString() ?? '',
        code: json['code']?.toString() ?? json['codigo']?.toString(),
        description: json['description']?.toString() ?? json['descripcion']?.toString(),
      );
    }
    return const CatalogItem(id: '', name: '');
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'description': description,
  };
}

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.image,
  });

  final int id;
  final String name;
  final String? description;
  final String? image;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
    name: json['name']?.toString() ?? json['Name']?.toString() ?? '',
    description: json['description']?.toString() ?? json['Description']?.toString(),
    image: json['image']?.toString() ?? json['Image']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'image': image,
  };
}

import 'package:polleria_movil/api/models/category_models.dart';

class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.basePrice,
    required this.salePrice,
    required this.categoryId,
    this.image,
    this.category,
    this.isOnSale = false,
  });

  final int id;
  final String name;
  final String? description;
  final double basePrice;
  final double salePrice;
  final int categoryId;
  final String? image;
  final CategoryModel? category;
  final bool isOnSale;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
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

    return ProductModel(
      id: parseInt(json['id'] ?? json['Id']),
      name: json['name']?.toString() ?? json['Name']?.toString() ?? '',
      description: json['description']?.toString() ?? json['Description']?.toString(),
      basePrice: parseDouble(json['basePrice'] ?? json['BasePrice']),
      salePrice: parseDouble(json['salePrice'] ?? json['SalePrice'] ?? json['price'] ?? json['Price']),
      categoryId: parseInt(json['categoryId'] ?? json['CategoryId']),
      image: json['imageUrl']?.toString() ??
          json['ImageUrl']?.toString() ??
          json['image']?.toString() ??
          json['Image']?.toString(),
      category: json['category'] is Map<String, dynamic>
          ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      isOnSale: json['isOnSale'] == true || json['IsOnSale'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'basePrice': basePrice,
    'salePrice': salePrice,
    'categoryId': categoryId,
    'image': image,
    'isOnSale': isOnSale,
  };
}

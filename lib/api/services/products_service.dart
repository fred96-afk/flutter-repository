import 'package:polleria_movil/api/api_client.dart';
import 'package:polleria_movil/api/models/product_models.dart';

class ProductsService {
  ProductsService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<ProductModel>> getProducts() async {
    final response = await _apiClient.get('/api/Products');
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<ProductModel>> getProductsPaged({
    int pageNumber = 1,
    int pageSize = 20,
    String? term,
  }) async {
    final params = <String, dynamic>{
      'PageNumber': pageNumber,
      'PageSize': pageSize,
      if (term != null && term.isNotEmpty) 'term': term,
    };
    final response = await _apiClient.get('/api/Products/paged', queryParameters: params);
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .toList();
    } else if (response is Map<String, dynamic> && response['items'] is List) {
      return (response['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<ProductModel>> searchProducts(String term) async {
    final response = await _apiClient.get(
      '/api/Products/search',
      queryParameters: {'term': term},
    );
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .toList();
    }
    return [];
  }

  Future<ProductModel> getProductById(int id) async {
    final response = await _apiClient.get('/api/Products/$id');
    return ProductModel.fromJson(response as Map<String, dynamic>);
  }
}

import 'package:polleria_movil/api/api_client.dart';
import 'package:polleria_movil/api/models/category_models.dart';

class CategoriesService {
  CategoriesService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<CategoryModel>> getCategories() async {
    final response = await _apiClient.get('/api/Categories');
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(CategoryModel.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<CategoryModel>> getCategoriesPaged({
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{
      'PageNumber': pageNumber,
      'PageSize': pageSize,
    };
    final response = await _apiClient.get('/api/Categories/paged', queryParameters: params);
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(CategoryModel.fromJson)
          .toList();
    } else if (response is Map<String, dynamic> && response['items'] is List) {
      return (response['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(CategoryModel.fromJson)
          .toList();
    }
    return [];
  }

  Future<CategoryModel> getCategoryById(int id) async {
    final response = await _apiClient.get('/api/Categories/$id');
    return CategoryModel.fromJson(response as Map<String, dynamic>);
  }
}

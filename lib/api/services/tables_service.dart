import 'package:polleria_movil/api/api_client.dart';
import 'package:polleria_movil/api/models/table_models.dart';

class TablesService {
  TablesService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// Obtiene la lista completa de mesas desde el backend (`/api/Tables`),
  /// opcionalmente filtrada por [mapId].
  Future<List<RestaurantTableModel>> getTables({String? mapId}) async {
    final path = mapId != null && mapId.isNotEmpty
        ? '/api/Tables?mapId=${Uri.encodeComponent(mapId)}'
        : '/api/Tables';

    final response = await _apiClient.get(path);
    if (response is List) {
      final tables = <RestaurantTableModel>[];
      for (final item in response) {
        if (item is Map<String, dynamic>) {
          tables.add(RestaurantTableModel.fromJson(item));
        }
      }
      return tables;
    }
    return [];
  }

  /// Obtiene una mesa específica por su ID numérico.
  Future<RestaurantTableModel?> getTableById(int id) async {
    final response = await _apiClient.get('/api/Tables/$id');
    if (response is Map<String, dynamic>) {
      return RestaurantTableModel.fromJson(response);
    }
    return null;
  }

  /// Obtiene una mesa específica por su número de mesa.
  Future<RestaurantTableModel?> getTableByNumber(String number) async {
    final response = await _apiClient.get('/api/Tables/number/$number');
    if (response is Map<String, dynamic>) {
      return RestaurantTableModel.fromJson(response);
    }
    return null;
  }
}

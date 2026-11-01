import 'package:polleria_movil/api/api_client.dart';
import 'package:polleria_movil/api/models/catalog_models.dart';

class CatalogoService {
  CatalogoService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<CatalogItem>> getTiposDocumento() async {
    final response = await _apiClient.get('/api/Catalogos/tipos-documento');
    return _parseList(response);
  }

  Future<List<CatalogItem>> getMetodosPago() async {
    final response = await _apiClient.get('/api/Catalogos/metodos-pago');
    return _parseList(response);
  }

  Future<List<CatalogItem>> getTiposComprobante() async {
    final response = await _apiClient.get('/api/Catalogos/tipos-comprobante');
    return _parseList(response);
  }

  Future<List<CatalogItem>> getEstadosPedido() async {
    final response = await _apiClient.get('/api/Catalogos/estados-pedido');
    return _parseList(response);
  }

  Future<List<CatalogItem>> getCargos() async {
    final response = await _apiClient.get('/api/Catalogos/cargos');
    return _parseList(response);
  }

  Future<List<CatalogItem>> getCategoriasProducto() async {
    final response = await _apiClient.get('/api/Catalogos/categorias-producto');
    return _parseList(response);
  }

  List<CatalogItem> _parseList(dynamic response) {
    if (response is List) {
      return response.map(CatalogItem.fromJson).toList();
    }
    return [];
  }
}

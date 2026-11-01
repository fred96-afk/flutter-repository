import 'package:polleria_movil/api/api_client.dart';
import 'package:polleria_movil/api/models/order_models.dart';

class OrdersService {
  OrdersService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<OrderResponse>> getOrders() async {
    final response = await _apiClient.get('/api/Pedidos');
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(OrderResponse.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<OrderResponse>> getDeliveryOrders() async {
    final response = await _apiClient.get('/api/Pedidos/delivery');
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(OrderResponse.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<OrderResponse>> getOrdersByTable(String tableNumber) async {
    final response = await _apiClient.get('/api/Pedidos/mesa/$tableNumber');
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(OrderResponse.fromJson)
          .toList();
    } else if (response is Map<String, dynamic>) {
      return [OrderResponse.fromJson(response)];
    }
    return [];
  }

  Future<OrderResponse> getOrderById(int id) async {
    final response = await _apiClient.get('/api/Pedidos/$id');
    return OrderResponse.fromJson(response as Map<String, dynamic>);
  }

  Future<dynamic> createOrder(OrderRequest request) async {
    return _apiClient.post(
      '/api/Pedidos',
      body: request.toJson(),
    );
  }

  Future<dynamic> deleteOrder(int id) async {
    return _apiClient.delete('/api/Pedidos/$id');
  }

  Future<dynamic> generateInvoice(int id) async {
    return _apiClient.post('/api/Pedidos/$id/invoice');
  }

  Future<dynamic> updateStatus(int id, StatusUpdateRequest request) async {
    return _apiClient.patch(
      '/api/Pedidos/$id/status',
      body: request.toJson(),
    );
  }

  Future<dynamic> updatePaymentStatus(int id, StatusUpdateRequest request) async {
    return _apiClient.patch(
      '/api/Pedidos/$id/payment-status',
      body: request.toJson(),
    );
  }

  Future<dynamic> acceptDelivery(int id, AcceptDeliveryRequest request) async {
    return _apiClient.post(
      '/api/Pedidos/$id/accept-delivery',
      body: request.toJson(),
    );
  }
}

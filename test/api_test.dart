import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:polleria_movil/api/api.dart';
import 'package:polleria_movil/data/restaurant_store.dart';

Dio createMockDio(Response<dynamic> Function(RequestOptions options) handler) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.instance.baseUrl,
      validateStatus: (status) => true,
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, reqHandler) {
        try {
          final response = handler(options);
          if ((response.statusCode ?? 200) >= 400) {
            return reqHandler.reject(
              DioException(
                requestOptions: options,
                response: response,
                type: DioExceptionType.badResponse,
              ),
            );
          }
          return reqHandler.resolve(response);
        } on DioException catch (e) {
          return reqHandler.reject(e);
        } catch (e) {
          return reqHandler.reject(
            DioException(requestOptions: options, error: e),
          );
        }
      },
    ),
  );
  return dio;
}

void main() {
  group('ApiConfig', () {
    test('defaults and URL manipulation', () {
      final config = ApiConfig.instance;
      expect(config.baseUrl, isNotEmpty);

      config.baseUrl = 'http://testserver:5000/';
      expect(config.baseUrl, 'http://testserver:5000');

      config.setAuthToken('test-jwt-token');
      expect(config.isAuthenticated, isTrue);
      expect(config.authToken, 'test-jwt-token');

      final headers = config.headers();
      expect(headers['Authorization'], 'Bearer test-jwt-token');
      expect(headers['Content-Type'], 'application/json');

      config.clearAuth();
      expect(config.isAuthenticated, isFalse);
      expect(config.authToken, isNull);
    });
  });

  group('API Models Serialization', () {
    test('Auth models', () {
      const login = LoginRequest(email: 'admin@polleria.com', password: 'secret');
      expect(login.toJson(), {
        'email': 'admin@polleria.com',
        'password': 'secret',
      });

      final authResp = AuthResponse.fromJson({
        'token': 'jwt-1234',
        'email': 'admin@polleria.com',
        'name': 'Administrador',
        'roleId': 1,
      });
      expect(authResp.token, 'jwt-1234');
      expect(authResp.email, 'admin@polleria.com');
      expect(authResp.roleId, 1);

      const userReq = UserRequest(
        name: 'Cliente Juan',
        email: 'juan@gmail.com',
        password: 'pass',
        roleId: 2,
      );
      expect(userReq.toJson()['name'], 'Cliente Juan');

      const forgot = ForgotPasswordRequest(email: 'test@polleria.com');
      expect(forgot.toJson()['email'], 'test@polleria.com');

      const reset = ResetPasswordRequest(token: 't-123', newPassword: 'new');
      expect(reset.toJson()['token'], 't-123');
      expect(reset.toJson()['newPassword'], 'new');
    });

    test('Category and Product models', () {
      final cat = CategoryModel.fromJson({
        'id': 1,
        'name': 'Pollo a la brasa',
        'description': 'Especialidad',
        'image': 'pollo.png',
      });
      expect(cat.id, 1);
      expect(cat.name, 'Pollo a la brasa');
      expect(cat.toJson()['id'], 1);

      final prod = ProductModel.fromJson({
        'id': 101,
        'name': '1/4 de Pollo Especial',
        'description': 'Con papas y ensalada',
        'basePrice': 15.5,
        'salePrice': 18.0,
        'categoryId': 1,
        'image': 'cuarto.png',
        'category': cat.toJson(),
      });
      expect(prod.id, 101);
      expect(prod.name, '1/4 de Pollo Especial');
      expect(prod.salePrice, 18.0);
      expect(prod.category?.name, 'Pollo a la brasa');

      // Test mapping to MenuProduct
      final menuProduct = MenuProduct.fromProductModel(prod);
      expect(menuProduct.id, '101');
      expect(menuProduct.name, '1/4 de Pollo Especial');
      expect(menuProduct.price, 18.0);
      expect(menuProduct.category, MenuCategory.polloALaBrasa);
    });

    test('Order models', () {
      const detail = OrderDetailRequest(productId: 5, sideId: 2, quantity: 3);
      expect(detail.toJson(), {
        'productId': 5,
        'sideId': 2,
        'quantity': 3,
      });

      const orderReq = OrderRequest(
        clientId: 10,
        userId: 1,
        tableNumber: '4',
        customerName: 'Augusto',
        details: [detail],
      );
      final json = orderReq.toJson();
      expect(json['tableNumber'], '4');
      expect(json['customerName'], 'Augusto');
      expect((json['details'] as List).length, 1);

      const statusReq = StatusUpdateRequest(status: 'Entregado', valor: 'OK');
      expect(statusReq.toJson()['status'], 'Entregado');

      final orderResp = OrderResponse.fromJson({
        'id': 200,
        'tableNumber': '4',
        'customerName': 'Augusto',
        'total': 54.0,
        'status': 'Pendiente',
        'details': [
          {
            'id': 1,
            'productId': 5,
            'productName': '1/4 de pollo',
            'price': 18.0,
            'quantity': 3,
            'subtotal': 54.0,
          }
        ],
      });
      expect(orderResp.id, 200);
      expect(orderResp.tableNumber, '4');
      expect(orderResp.items.length, 1);
      expect(orderResp.items.first.productName, '1/4 de pollo');
    });

    test('CatalogItem model', () {
      final item = CatalogItem.fromJson({
        'id': 'DNI',
        'name': 'Documento Nacional de Identidad',
      });
      expect(item.id, 'DNI');
      expect(item.name, 'Documento Nacional de Identidad');
    });
  });

  group('ApiClient with Dio and PrettyDioLogger', () {
    test('default Dio instance attaches PrettyDioLogger', () {
      final client = ApiClient();
      expect(client.dio, isA<Dio>());
      expect(
        client.dio.interceptors.any((i) => i is PrettyDioLogger),
        isTrue,
      );
    });

    test('ApiClient handles GET, POST, PUT, PATCH, DELETE and errors', () async {
      final mockDio = createMockDio((options) {
        if (options.path.endsWith('/api/test-get')) {
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: {'result': 'ok'},
          );
        }
        if (options.path.endsWith('/api/test-post')) {
          return Response(
            requestOptions: options,
            statusCode: 201,
            data: {'created': true, 'data': options.data},
          );
        }
        if (options.path.endsWith('/api/test-put')) {
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: {'updated': true},
          );
        }
        if (options.path.endsWith('/api/test-patch')) {
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: {'patched': true},
          );
        }
        if (options.path.endsWith('/api/test-delete')) {
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: {'deleted': true},
          );
        }
        if (options.path.endsWith('/api/error-400')) {
          return Response(
            requestOptions: options,
            statusCode: 400,
            data: {'message': 'Datos inválidos'},
          );
        }
        return Response(
          requestOptions: options,
          statusCode: 404,
          data: 'Not Found',
        );
      });

      final client = ApiClient(dio: mockDio);

      final getRes = await client.get('/api/test-get');
      expect(getRes['result'], 'ok');

      final postRes = await client.post('/api/test-post', body: {'name': 'test'});
      expect(postRes['created'], isTrue);

      final putRes = await client.put('/api/test-put', body: {'name': 'put'});
      expect(putRes['updated'], isTrue);

      final patchRes = await client.patch('/api/test-patch', body: {'name': 'patch'});
      expect(patchRes['patched'], isTrue);

      final deleteRes = await client.delete('/api/test-delete');
      expect(deleteRes['deleted'], isTrue);

      expect(
        () => client.get('/api/error-400'),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Datos inválidos',
        )),
      );
    });

    test('ApiClient testConnection success and failure', () async {
      final mockDio = createMockDio((options) {
        if (options.path.contains('/api/Catalog')) {
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: 'OK',
          );
        }
        return Response(
          requestOptions: options,
          statusCode: 404,
          data: 'Not Found',
        );
      });

      final client = ApiClient(dio: mockDio);
      final result = await client.testConnection('http://testserver:5000');
      expect(result.success, isTrue);
      expect(result.statusCode, 200);
      expect(result.message, contains('Conexión exitosa'));
    });
  });

  group('Services with Mock Dio Client', () {
    test('AuthService login calls /api/Auth/login', () async {
      final mockDio = createMockDio((options) {
        if (options.path.endsWith('/api/Auth/login')) {
          final body = options.data is String ? jsonDecode(options.data) : options.data;
          if (body['email'] == 'augusto@polleria.com' && body['password'] == '123456') {
            return Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'token': 'mock-jwt-token-777',
                'email': 'augusto@polleria.com',
                'name': 'Augusto',
                'roleId': 1,
              },
            );
          }
          return Response(
            requestOptions: options,
            statusCode: 401,
            data: {'message': 'Credenciales invalidas'},
          );
        }
        return Response(
          requestOptions: options,
          statusCode: 404,
          data: 'Not Found',
        );
      });

      final authService = AuthService(apiClient: ApiClient(dio: mockDio));
      final response = await authService.login('augusto@polleria.com', '123456');
      expect(response.token, 'mock-jwt-token-777');
      expect(ApiConfig.instance.authToken, 'mock-jwt-token-777');
    });

    test('ProductsService calls /api/Products', () async {
      final mockDio = createMockDio((options) {
        if (options.path.endsWith('/api/Products')) {
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: [
              {
                'id': 1,
                'name': 'Pollo Entero a la Brasa',
                'basePrice': 45.0,
                'salePrice': 48.0,
                'categoryId': 1,
              },
              {
                'id': 2,
                'name': 'Parrilla Mixta',
                'basePrice': 20.0,
                'salePrice': 25.0,
                'categoryId': 2,
              }
            ],
          );
        }
        return Response(
          requestOptions: options,
          statusCode: 404,
          data: 'Not Found',
        );
      });

      final service = ProductsService(apiClient: ApiClient(dio: mockDio));
      final products = await service.getProducts();
      expect(products.length, 2);
      expect(products.first.name, 'Pollo Entero a la Brasa');
      expect(products.last.salePrice, 25.0);
    });

    test('OrdersService creates order on /api/Pedidos', () async {
      final mockDio = createMockDio((options) {
        if (options.path.endsWith('/api/Pedidos') && options.method.toUpperCase() == 'POST') {
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'id': 999,
              'tableNumber': '7',
              'status': 'Registrado',
            },
          );
        }
        return Response(
          requestOptions: options,
          statusCode: 404,
          data: 'Not Found',
        );
      });

      final service = OrdersService(apiClient: ApiClient(dio: mockDio));
      final response = await service.createOrder(
        const OrderRequest(
          tableNumber: '7',
          details: [OrderDetailRequest(productId: 1, quantity: 2)],
        ),
      );
      expect(response['id'], 999);
      expect(response['tableNumber'], '7');
    });

    test('CatalogoService calls /api/Catalogos/metodos-pago', () async {
      final mockDio = createMockDio((options) {
        if (options.path.endsWith('/api/Catalogos/metodos-pago')) {
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: [
              {'id': 1, 'name': 'Efectivo'},
              {'id': 2, 'name': 'Tarjeta Visa / Master'},
              {'id': 3, 'name': 'Yape / Plin'},
            ],
          );
        }
        return Response(
          requestOptions: options,
          statusCode: 404,
          data: 'Not Found',
        );
      });

      final service = CatalogoService(apiClient: ApiClient(dio: mockDio));
      final items = await service.getMetodosPago();
      expect(items.length, 3);
      expect(items[0].name, 'Efectivo');
      expect(items[2].name, 'Yape / Plin');
    });
  });
}

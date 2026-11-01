import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:polleria_movil/api/api_config.dart';
import 'package:polleria_movil/services/inactivity_service.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.message,
    this.body,
  });

  final int statusCode;
  final String message;
  final dynamic body;

  @override
  String toString() => 'ApiException(status: $statusCode, message: $message)';
}

class ApiClient {
  ApiClient({Dio? dio, dynamic client})
      : _dio = dio ?? (client is Dio ? client : defaultDio);

  static Dio? _sharedDio;

  /// Retorna o inicializa la instancia compartida de Dio con sus interceptores
  /// y PrettyDioLogger configurados.
  static Dio get defaultDio => _sharedDio ??= createDio();

  /// Reinicia la instancia compartida de Dio (útil para pruebas o reconfiguración).
  static void resetDefaultDio() {
    _sharedDio?.close();
    _sharedDio = null;
  }

  /// Crea una nueva instancia de Dio con interceptor de autenticación/URL
  /// y PrettyDioLogger para registro detallado en consola.
  static Dio createDio({bool enableLogger = true}) {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptor dinámico para baseUrl y token de autenticación
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (!options.path.startsWith('http://') &&
              !options.path.startsWith('https://')) {
            options.baseUrl = ApiConfig.instance.baseUrl;
          }
          final token = ApiConfig.instance.authToken;
          if (token != null &&
              token.isNotEmpty &&
              !options.headers.containsKey('Authorization')) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          if (error.response?.statusCode == 401 &&
              ApiConfig.instance.isAuthenticated) {
            InactivityService.instance.handleUnauthorized401();
          }
          return handler.next(error);
        },
      ),
    );

    // Permitir certificados SSL autofirmados en desarrollo local (ej. ASP.NET Core en https://localhost:7200)
    if (!kIsWeb && dio.httpClientAdapter is IOHttpClientAdapter) {
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }

    // Logger visual para requests, responses y errores de la API
    if (enableLogger) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }

    return dio;
  }

  final Dio _dio;
  Dio get dio => _dio;

  Duration get timeout => _dio.options.connectTimeout ?? const Duration(seconds: 8);

  Future<({bool success, int? statusCode, String message})> testConnection([
    String? targetUrl,
  ]) async {
    var base = (targetUrl ?? ApiConfig.instance.baseUrl).trim();
    if (!base.startsWith('http://') && !base.startsWith('https://')) {
      base = 'http://$base';
    }
    final cleanBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;

    try {
      final response = await _dio.get(
        '$cleanBase/api/Catalog',
        options: Options(
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
          validateStatus: (status) => true,
        ),
      );
      final statusCode = response.statusCode;
      if (statusCode != null && statusCode >= 200 && statusCode < 400) {
        return (
          success: true,
          statusCode: statusCode,
          message: 'Conexión exitosa con el backend (HTTP $statusCode)',
        );
      } else {
        return (
          success: false,
          statusCode: statusCode,
          message: 'El servidor respondió con código HTTP $statusCode',
        );
      }
    } catch (_) {
      try {
        final response = await _dio.get(
          cleanBase,
          options: Options(
            sendTimeout: const Duration(seconds: 2),
            receiveTimeout: const Duration(seconds: 2),
            validateStatus: (status) => true,
          ),
        );
        final statusCode = response.statusCode;
        return (
          success: true,
          statusCode: statusCode,
          message: 'Servidor alcanzado (HTTP $statusCode)',
        );
      } catch (e) {
        return (
          success: false,
          statusCode: null,
          message: 'No se pudo conectar al servidor: ${e.toString().split('\n').first}',
        );
      }
    }
  }

  String _buildUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final base = ApiConfig.instance.baseUrl;
    final cleanBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$cleanBase$cleanPath';
  }

  Options _buildOptions({Map<String, String>? headers}) {
    final mergedHeaders = ApiConfig.instance.headers(extraHeaders: headers);
    return Options(headers: mergedHeaders);
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final url = _buildUrl(path);
    try {
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: _buildOptions(headers: headers),
      );
      return _processResponse(response);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'Error inesperado: ${e.toString().split('\n').first}',
      );
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final url = _buildUrl(path);
    try {
      final response = await _dio.post(
        url,
        data: body,
        queryParameters: queryParameters,
        options: _buildOptions(headers: headers),
      );
      return _processResponse(response);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'Error inesperado: ${e.toString().split('\n').first}',
      );
    }
  }

  Future<dynamic> put(
    String path, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final url = _buildUrl(path);
    try {
      final response = await _dio.put(
        url,
        data: body,
        options: _buildOptions(headers: headers),
      );
      return _processResponse(response);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'Error inesperado: ${e.toString().split('\n').first}',
      );
    }
  }

  Future<dynamic> patch(
    String path, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final url = _buildUrl(path);
    try {
      final response = await _dio.patch(
        url,
        data: body,
        options: _buildOptions(headers: headers),
      );
      return _processResponse(response);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'Error inesperado: ${e.toString().split('\n').first}',
      );
    }
  }

  Future<dynamic> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    final url = _buildUrl(path);
    try {
      final response = await _dio.delete(
        url,
        options: _buildOptions(headers: headers),
      );
      return _processResponse(response);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'Error inesperado: ${e.toString().split('\n').first}',
      );
    }
  }

  dynamic _processResponse(Response response) {
    final decoded = _extractData(response.data);
    final statusCode = response.statusCode ?? 200;

    if (statusCode >= 200 && statusCode < 300) {
      return decoded;
    }

    String message = 'Error en la petición ($statusCode)';
    if (decoded is Map<String, dynamic>) {
      if (decoded['message'] != null) {
        message = decoded['message'].toString();
      } else if (decoded['title'] != null) {
        message = decoded['title'].toString();
      } else if (decoded['error'] != null) {
        message = decoded['error'].toString();
      }
    } else if (decoded is String && decoded.isNotEmpty) {
      message = decoded;
    }

    throw ApiException(
      statusCode: statusCode,
      message: message,
      body: decoded,
    );
  }

  dynamic _extractData(dynamic data) {
    if (data is String && data.isNotEmpty) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  ApiException _handleDioException(DioException e) {
    final response = e.response;
    if (response != null) {
      final statusCode = response.statusCode ?? 0;
      final decoded = _extractData(response.data);
      String message = 'Error en la petición ($statusCode)';
      if (decoded is Map<String, dynamic>) {
        if (decoded['message'] != null) {
          message = decoded['message'].toString();
        } else if (decoded['title'] != null) {
          message = decoded['title'].toString();
        } else if (decoded['error'] != null) {
          message = decoded['error'].toString();
        }
      } else if (decoded is String && decoded.isNotEmpty) {
        message = decoded;
      }

      return ApiException(
        statusCode: statusCode,
        message: message,
        body: decoded,
      );
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiException(
        statusCode: 0,
        message: 'Tiempo de espera agotado al conectar con el servidor',
      );
    }

    if (e.type == DioExceptionType.cancel) {
      return ApiException(
        statusCode: 0,
        message: 'Petición cancelada',
      );
    }

    final rawErr = e.error;
    if (rawErr is HandshakeException) {
      return ApiException(
        statusCode: 0,
        message: 'Error de certificado SSL/HTTPS con el servidor: ${rawErr.message}',
      );
    }

    if (rawErr is SocketException) {
      return ApiException(
        statusCode: 0,
        message: 'No se pudo conectar al servidor: ${rawErr.message}',
      );
    }

    final msg = (e.message != null && e.message!.isNotEmpty)
        ? e.message!
        : (rawErr?.toString() ?? 'Error de conexión desconocido');
    return ApiException(
      statusCode: 0,
      message: 'No se pudo conectar al servidor: ${msg.split('\n').first}',
    );
  }
}

import 'package:polleria_movil/api/api_client.dart';
import 'package:polleria_movil/api/api_config.dart';
import 'package:polleria_movil/api/models/auth_models.dart';
import 'package:polleria_movil/data/app_storage.dart';

class AuthService {
  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/api/Auth/login',
        body: LoginRequest(email: email, password: password).toJson(),
      );
      final auth = AuthResponse.fromJson(response);
      if (auth.token.isNotEmpty) {
        ApiConfig.instance.setAuthToken(auth.token);
        AppStorage.setUserData(auth.toJson());
      }
      return auth;
    } on ApiException catch (e) {
      // Si el backend responde que roles de personal (Mozo/Admin) deben usar adminlogin,
      // reintentamos automáticamente con adminLogin.
      if (e.message.contains('/adminlogin') || e.statusCode == 400) {
        return adminLogin(email, password);
      }
      rethrow;
    }
  }

  Future<AuthResponse> adminLogin(String email, String password) async {
    final response = await _apiClient.post(
      '/api/Auth/adminlogin',
      body: LoginRequest(email: email, password: password).toJson(),
    );
    final auth = AuthResponse.fromJson(response);
    if (auth.token.isNotEmpty) {
      ApiConfig.instance.setAuthToken(auth.token);
      AppStorage.setUserData(auth.toJson());
    }
    return auth;
  }

  Future<dynamic> registerClient(UserRequest request) async {
    return _apiClient.post(
      '/api/Auth/registerclient',
      body: request.toJson(),
    );
  }

  Future<dynamic> verifyEmail(String token) async {
    return _apiClient.get(
      '/api/Auth/verify-email',
      queryParameters: {'token': token},
    );
  }

  Future<dynamic> forgotPassword(String email) async {
    return _apiClient.post(
      '/api/Auth/forgot-password',
      body: ForgotPasswordRequest(email: email).toJson(),
    );
  }

  Future<dynamic> resetPassword(String token, String newPassword) async {
    return _apiClient.post(
      '/api/Auth/reset-password',
      body: ResetPasswordRequest(token: token, newPassword: newPassword).toJson(),
    );
  }

  void logout() {
    ApiConfig.instance.clearAuth();
    AppStorage.setUserData(null);
  }
}

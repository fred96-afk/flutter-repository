import 'package:flutter/foundation.dart';
import 'package:polleria_movil/config/backend_url.dart';
import 'package:polleria_movil/data/app_storage.dart';

class ApiConfig extends ChangeNotifier {
  ApiConfig._();

  static final ApiConfig instance = ApiConfig._();

  /// Default API base URL defined in [lib/config/backend_url.dart].
  String _baseUrl = defaultBaseUrl;

  /// Default base URL resolved from [BackendUrlConstants.platformDefault].
  static String get defaultBaseUrl => BackendUrlConstants.platformDefault;

  String get baseUrl => _baseUrl;

  void setBaseUrl(String url, {bool persist = true}) {
    final trimmed = url.trim();
    final clean = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    if (_baseUrl != clean) {
      _baseUrl = clean;
      if (persist) {
        AppStorage.setBaseUrl(clean);
      }
      notifyListeners();
    }
  }

  set baseUrl(String url) => setBaseUrl(url);

  String? _authToken;

  String? get authToken => _authToken;

  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;

  void setAuthToken(String? token, {bool persist = true}) {
    if (_authToken != token) {
      _authToken = token;
      if (persist) {
        AppStorage.setAuthToken(token);
      }
      notifyListeners();
    }
  }

  void clearAuth({bool persist = true}) {
    if (_authToken != null) {
      _authToken = null;
      if (persist) {
        AppStorage.setAuthToken(null);
      }
      notifyListeners();
    }
  }

  Map<String, String> headers({Map<String, String>? extraHeaders}) {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      map['Authorization'] = 'Bearer $_authToken';
    }
    if (extraHeaders != null) {
      map.addAll(extraHeaders);
    }
    return map;
  }
}

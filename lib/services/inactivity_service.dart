import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:polleria_movil/api/api_config.dart';
import 'package:polleria_movil/data/app_storage.dart';

/// Servicio de control de inactividad (10 minutos) y expiración de token (1h 30m / 90 minutos)
class InactivityService with WidgetsBindingObserver {
  InactivityService._();

  static final InactivityService instance = InactivityService._();

  static const Duration inactivityLimit = Duration(minutes: 10);
  static const Duration tokenMaxLifetime = Duration(minutes: 90); // 1 hora y media
  static const Duration checkInterval = Duration(seconds: 10);

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Timer? _timer;
  DateTime? _lastActivityTime;
  DateTime? _tokenIssuedAt;
  DateTime? _lastRecordedThrottle;
  bool _isInitialized = false;

  static bool get isTestEnvironment {
    try {
      return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  void init() {
    if (_isInitialized) return;
    _isInitialized = true;

    WidgetsBinding.instance.addObserver(this);

    if (ApiConfig.instance.isAuthenticated) {
      _restoreOrInitTimestamps();
      _startTimer();
    }

    ApiConfig.instance.addListener(_onAuthChanged);
  }

  void dispose() {
    _stopTimer();
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
      ApiConfig.instance.removeListener(_onAuthChanged);
      _isInitialized = false;
    }
  }

  void _onAuthChanged() {
    if (ApiConfig.instance.isAuthenticated) {
      final now = DateTime.now();
      _lastActivityTime = now;
      _tokenIssuedAt = now;
      AppStorage.setLastActivity(now);
      AppStorage.setTokenIssuedAt(now);
      _startTimer();
    } else {
      _stopTimer();
      _lastActivityTime = null;
      _tokenIssuedAt = null;
      AppStorage.clearSessionTimestamps();
    }
  }

  void _restoreOrInitTimestamps() {
    final now = DateTime.now();
    _lastActivityTime = AppStorage.getLastActivity() ?? now;
    _tokenIssuedAt = AppStorage.getTokenIssuedAt() ?? now;

    // Verificar si ya expiró mientras la aplicación estuvo cerrada
    _checkExpiration(now);
  }

  /// Registra interacción del usuario (touch, scroll, teclado)
  void recordActivity({bool force = false}) {
    if (!ApiConfig.instance.isAuthenticated) return;

    final now = DateTime.now();
    // Throttle de 2 segundos para no sobrecargar el almacenamiento en disco
    if (!force &&
        _lastRecordedThrottle != null &&
        now.difference(_lastRecordedThrottle!) < const Duration(seconds: 2)) {
      return;
    }

    _lastRecordedThrottle = now;
    _lastActivityTime = now;
    AppStorage.setLastActivity(now);
  }

  void _startTimer() {
    _timer?.cancel();
    if (isTestEnvironment) return; // En tests no iniciar timers periódicos pendientes

    _timer = Timer.periodic(checkInterval, (_) {
      _checkExpiration(DateTime.now());
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && ApiConfig.instance.isAuthenticated) {
      _checkExpiration(DateTime.now());
    }
  }

  void _checkExpiration(DateTime now) {
    if (!ApiConfig.instance.isAuthenticated) return;

    // 1. Verificar inactividad (10 minutos)
    final lastActivity = _lastActivityTime ?? AppStorage.getLastActivity() ?? now;
    if (now.difference(lastActivity) >= inactivityLimit) {
      logoutDueToInactivity();
      return;
    }

    // 2. Verificar caducidad total del token (hora y media / 90 minutos)
    final issuedAt = _tokenIssuedAt ?? AppStorage.getTokenIssuedAt() ?? now;
    if (now.difference(issuedAt) >= tokenMaxLifetime) {
      logoutDueToTokenExpired();
      return;
    }
  }

  void logoutDueToInactivity() {
    _performLogout('Tu sesión ha expirado por inactividad (10 minutos sin actividad).');
  }

  void logoutDueToTokenExpired() {
    _performLogout('Tu sesión ha caducado (1 hora y media). Por favor inicia sesión nuevamente.');
  }

  void handleUnauthorized401() {
    _performLogout('Tu sesión ha expirado o es inválida. Inicia sesión nuevamente.');
  }

  void _performLogout(String message) {
    if (!ApiConfig.instance.isAuthenticated) return;

    _stopTimer();
    ApiConfig.instance.clearAuth();
    AppStorage.clearSessionTimestamps();

    final nav = navigatorKey.currentState;
    if (nav != null) {
      nav.pushNamedAndRemoveUntil('/login', (route) => false);

      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange.shade900,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// Widget detector de interacción táctil que envuelve la app sin bloquear gestos
class InactivityDetector extends StatelessWidget {
  const InactivityDetector({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => InactivityService.instance.recordActivity(),
      onPointerMove: (_) => InactivityService.instance.recordActivity(),
      child: child,
    );
  }
}

import 'package:flutter/foundation.dart';

/// ============================================================================
/// CONFIGURACIÓN DE LA URL DEL BACKEND
/// ============================================================================
///
/// Modifica la variable [defaultBackendUrl] o pasa el argumento `--dart-define=BACKEND_URL=...`
/// para cambiar la dirección del backend de forma centralizada en toda la aplicación.
///
/// Ejemplos comunes:
/// - Emulador Android: 'http://10.0.2.2:5000'
/// - Localhost (Web / Linux / Windows / macOS): 'http://localhost:5000'
/// - Celular físico conectado a la misma red Wi-Fi: 'http://192.168.1.100:5000'
/// - Servidor en la nube o staging: 'https://api.polleriaelgigante.com'
/// ============================================================================

/// URL base predeterminada que utiliza la aplicación en el código.
/// Cambia esta constante si deseas conectar la app a otro servidor por defecto.
const String defaultBackendUrl = 'https://localhost:7200';

/// URL base del backend activa en compilación (permite sobrescribir con `--dart-define`).
const String backendBaseUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: defaultBackendUrl,
);

/// Alias de compatibilidad
const String kBackendBaseUrl = backendBaseUrl;

/// Colección de constantes y utilidades de URL para diferentes entornos.
abstract final class BackendUrlConstants {
  /// URL predeterminada definida en este archivo
  static const String defaultUrl = defaultBackendUrl;

  /// URL común para el emulador Android (10.0.2.2 mapea a 127.0.0.1 de la PC anfitriona)
  static const String androidEmulator = 'http://10.0.2.2:5000';

  /// URL común para localhost en Web y plataformas de escritorio
  static const String localhost = 'http://localhost:5000';

  /// Ejemplo de URL para red local Wi-Fi / LAN
  static const String localNetworkExample = 'http://192.168.1.100:5000';

  /// Devuelve la URL por defecto según la plataforma actual,
  /// respetando si [defaultBackendUrl] ha sido personalizada.
  static String get platformDefault {
    // Si se especificó una URL mediante --dart-define, tiene prioridad
    if (const bool.hasEnvironment('BACKEND_URL')) {
      return backendBaseUrl;
    }

    // Si defaultBackendUrl fue editada a una IP o dominio personalizado, respetarla
    if (defaultBackendUrl != androidEmulator &&
        defaultBackendUrl != localhost) {
      return defaultBackendUrl;
    }

    if (kIsWeb) return localhost;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return androidEmulator;
    }
    return localhost;
  }
}

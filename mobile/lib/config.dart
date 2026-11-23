/// Configuración de compilación.
///
/// Se ajusta con `--dart-define`, por ejemplo:
/// ```
/// flutter run --dart-define=API_BASE_URL=https://mi-api.ejemplo.com/api
/// flutter run --dart-define=DEMO_MODE=true
/// ```
class AppConfig {
  AppConfig._();

  /// URL base de la API REST (carpeta `api/` del sitio PHP), sin barra final.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://judysimulator.wuaze.com/api',
  );

  /// Si es `true`, la app arranca directamente en modo demo (sin servidor).
  static const bool forceDemo = bool.fromEnvironment('DEMO_MODE');

  /// Sitio web público (para abrir en el navegador como respaldo).
  static const String webUrl = String.fromEnvironment(
    'WEB_URL',
    defaultValue: 'https://judysimulator.wuaze.com',
  );

  /// Versión instalada (igual a `version:` de pubspec.yaml).
  static const String appVersion = '0.1.0';
  static const int appVersionCode = 1;

  /// Página pública de descarga de la APK.
  static const String descargaUrl = '$webUrl/descargar.php';

  /// Aviso de privacidad público.
  static const String privacidadUrl = '$webUrl/privacidad.php';

  /// Tiempo máximo de espera de una petición HTTP.
  static const Duration timeout = Duration(seconds: 20);
}

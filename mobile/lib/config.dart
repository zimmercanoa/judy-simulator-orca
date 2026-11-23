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

  /// Tiempo máximo de espera de una petición HTTP.
  static const Duration timeout = Duration(seconds: 20);
}

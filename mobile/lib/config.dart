/// Configuración de compilación.
///
/// Se ajusta con `--dart-define`, por ejemplo:
/// ```
/// flutter run --dart-define=SITE_URL=https://micuenta.alwaysdata.net
/// flutter run --dart-define=API_BASE_URL=https://otra-api.ejemplo.com/api
/// flutter run --dart-define=DEMO_MODE=true
/// ```
///
/// El valor por defecto `https://CUENTA.alwaysdata.net` es un MARCADOR: hay
/// que reemplazar CUENTA por la cuenta real de alwaysdata (aquí o con
/// `--dart-define=SITE_URL=...`; en GitHub Actions, variable `SITE_URL`).
/// Mientras siga el marcador, la app arranca en modo demo.
class AppConfig {
  AppConfig._();

  static const String _marcador = 'CUENTA.alwaysdata.net';

  /// Sitio PHP completo (web + `api/`), sin barra final.
  static const String siteUrl = String.fromEnvironment(
    'SITE_URL',
    defaultValue: 'https://$_marcador',
  );

  /// URL base de la API REST (carpeta `api/` del sitio PHP), sin barra final.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '$siteUrl/api',
  );

  /// `false` mientras la URL siga siendo el marcador de alwaysdata.
  static bool get apiConfigurada => !apiBaseUrl.contains(_marcador);

  /// Si es `true`, la app arranca directamente en modo demo (sin servidor).
  static const bool forceDemo = bool.fromEnvironment('DEMO_MODE');

  /// Sitio web que se abre en el navegador (privacidad, descargas). Si la
  /// URL aún es el marcador, se usa el sitio de respaldo en InfinityFree,
  /// que funciona en navegadores.
  static String get webUrl => siteUrl.contains(_marcador)
      ? 'https://judysimulator.wuaze.com'
      : siteUrl;

  /// Versión instalada (igual a `version:` de pubspec.yaml).
  static const String appVersion = '0.1.0';
  static const int appVersionCode = 1;

  /// Página pública de descarga de la APK.
  static String get descargaUrl => '$webUrl/descargar.php';

  /// Aviso de privacidad público.
  static String get privacidadUrl => '$webUrl/privacidad.php';

  /// Tiempo máximo de espera de una petición HTTP.
  static const Duration timeout = Duration(seconds: 20);
}

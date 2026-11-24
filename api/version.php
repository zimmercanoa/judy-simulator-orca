<?php
// ============================================================
//  api/version.php — GET público: última versión de la app Android
//  para avisar de actualizaciones. Lee descargas/app.json.
// ============================================================
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/_bootstrap.php';
require_once __DIR__ . '/../app_version.php';

api_metodo(['GET']);

$app = judy_app_version();
api_responder(200, [
    'ok' => true,
    'version' => $app['version'],
    'version_code' => $app['version_code'],
    'publicada' => $app['publicada'],
    'android_minimo' => $app['android_minimo'],
    'descarga_url' => APP_URL . '/descargar.php',
    'release_url' => $app['release_url'],
    'notas' => $app['notas'],
]);

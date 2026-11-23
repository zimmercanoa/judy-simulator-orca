<?php
// ============================================================
//  app_version.php — Lee descargas/app.json (metadatos de la última
//  versión de la app Android). Lo usan descargar.php y api/version.php.
//  Las APK NO se alojan aquí: viven en GitHub Releases.
// ============================================================

const JUDY_RELEASES_URL = 'https://github.com/zimmercanoa/judy-simulator-orca/releases/latest';

/**
 * Devuelve los metadatos saneados de la versión publicada.
 * Solo se aceptan URLs https de github.com para las descargas.
 */
function judy_app_version(): array
{
    $vacio = [
        'version' => '',
        'version_code' => 0,
        'publicada' => false,
        'fecha' => '',
        'android_minimo' => 'Android 7.0 (API 24)',
        'release_url' => JUDY_RELEASES_URL,
        'notas' => '',
        'apks' => [],
    ];
    $raw = @file_get_contents(__DIR__ . '/descargas/app.json');
    $data = is_string($raw) ? json_decode($raw, true) : null;
    if (!is_array($data)) {
        return $vacio;
    }

    $es_url_github = static function ($url): bool {
        return is_string($url) && preg_match('#^https://github\.com/[\w.-]+/[\w.-]+/releases/#', $url) === 1;
    };

    $apks = [];
    foreach (($data['apks'] ?? []) as $apk) {
        if (!is_array($apk) || !$es_url_github($apk['url'] ?? null)) {
            continue;
        }
        $sha = strtolower((string)($apk['sha256'] ?? ''));
        $apks[] = [
            'abi' => (string)($apk['abi'] ?? ''),
            'archivo' => (string)($apk['archivo'] ?? ''),
            'tamano_bytes' => (int)($apk['tamano_bytes'] ?? 0),
            'sha256' => preg_match('/^[a-f0-9]{64}$/', $sha) ? $sha : '',
            'url' => (string)$apk['url'],
        ];
    }

    return [
        'version' => (string)($data['version'] ?? ''),
        'version_code' => (int)($data['version_code'] ?? 0),
        'publicada' => !empty($data['publicada']) && $apks !== [],
        'fecha' => (string)($data['fecha'] ?? ''),
        'android_minimo' => (string)($data['android_minimo'] ?? $vacio['android_minimo']),
        'release_url' => $es_url_github($data['release_url'] ?? null) ? (string)$data['release_url'] : JUDY_RELEASES_URL,
        'notas' => (string)($data['notas'] ?? ''),
        'apks' => $apks,
    ];
}

/** Tamaño legible (MB). */
function judy_tamano_legible(int $bytes): string
{
    return $bytes > 0 ? number_format($bytes / 1048576, 1) . ' MB' : '—';
}

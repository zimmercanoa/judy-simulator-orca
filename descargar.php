<?php
// ============================================================
//  descargar.php — Descarga de la app Android (APK).
//  Los archivos se alojan en GitHub Releases; aquí solo se muestran
//  versión, tamaño y SHA-256 leídos de descargas/app.json.
// ============================================================
session_start();
require_once __DIR__ . '/app_version.php';

$app = judy_app_version();
$h = static fn($v): string => htmlspecialchars((string)$v, ENT_QUOTES, 'UTF-8');

// APK recomendada: arm64-v8a (la mayoría de teléfonos desde 2017)
$recomendada = null;
foreach ($app['apks'] as $apk) {
    if ($apk['abi'] === 'arm64-v8a') {
        $recomendada = $apk;
        break;
    }
}
if ($recomendada === null && $app['apks'] !== []) {
    $recomendada = $app['apks'][0];
}
$descripcion_abi = [
    'arm64-v8a'   => 'Teléfonos de 64 bits (casi todos los actuales)',
    'armeabi-v7a' => 'Teléfonos antiguos de 32 bits',
    'x86_64'      => 'Emuladores y equipos con procesador Intel/AMD',
];
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Descargar app — JuDy Simulator</title>
    <link rel="stylesheet" href="assets/css/styles.css">
    <style>
        .doc { max-width:960px; margin:0 auto; padding:50px 20px; line-height:1.6; }
        .doc h1 { font-size:38px; margin-bottom:10px; }
        .doc h2 { font-size:22px; margin:34px 0 12px; color:var(--letras-especiales); }
        .tarjeta { background:var(--fondo-tarjeta); border:1px solid var(--borde-color);
                   border-radius:12px; padding:24px; margin-top:20px; }
        .tabla { width:100%; border-collapse:collapse; margin-top:10px; font-size:15px; }
        .tabla th, .tabla td { border:1px solid var(--borde-color); padding:10px; text-align:left; vertical-align:top; }
        .tabla th { background:var(--fondo-principal); }
        .sha { font-family:Consolas, monospace; font-size:12px; word-break:break-all; }
        .doc ol, .doc ul { margin-left:22px; }
        .doc li { margin-bottom:6px; }
        .aviso { border-left:4px solid var(--letras-especiales); padding:12px 16px; background:var(--fondo-tarjeta); margin-top:16px; }
        code { background:var(--fondo-principal); padding:2px 6px; border-radius:4px; }
    </style>
</head>
<body>

<?php $nav_tipo = 'publica'; include __DIR__ . '/navbar.php'; ?>

<main class="doc">
    <h1>App <span class="texto-naranja">JuDy Simulator</span> para Android</h1>
    <p>Consulta tu progreso en los módulos de realidad virtual, aprueba cuentas y edita avances (gerencia),
       pregunta al asistente virtual y repasa las normas NOM-009 y NOM-029 desde tu teléfono.</p>

    <div class="tarjeta">
        <?php if ($app['publicada'] && $recomendada !== null): ?>
            <p style="font-size:18px;"><strong>Versión <?= $h($app['version']) ?></strong>
                <?php if ($app['fecha'] !== ''): ?> · publicada el <?= $h($app['fecha']) ?><?php endif; ?>
                · requiere <?= $h($app['android_minimo']) ?> o superior</p>
            <p style="margin:18px 0;">
                <a class="btn-registro" style="font-size:20px; padding:15px 30px;" href="<?= $h($recomendada['url']) ?>" rel="noopener">
                    ⬇️ Descargar APK (<?= $h($recomendada['abi']) ?>, <?= $h(judy_tamano_legible($recomendada['tamano_bytes'])) ?>)
                </a>
            </p>
            <?php if ($app['notas'] !== ''): ?><p><strong>Novedades:</strong> <?= $h($app['notas']) ?></p><?php endif; ?>
            <p style="font-size:14px; color:var(--letras-secundarias);">
                ¿No sabes cuál elegir? Usa la recomendada; si al instalar aparece «La app no es compatible», prueba <code>armeabi-v7a</code>.
                Todas las versiones en <a href="<?= $h($app['release_url']) ?>" rel="noopener">GitHub Releases</a>.
            </p>
        <?php else: ?>
            <p style="font-size:18px;"><strong>La primera versión de la app se publicará muy pronto.</strong></p>
            <p>Cuando esté lista aparecerá aquí y en
               <a href="<?= $h($app['release_url']) ?>" rel="noopener">GitHub Releases</a>.
               Requiere <?= $h($app['android_minimo']) ?> o superior.</p>
        <?php endif; ?>
    </div>

    <?php if ($app['apks'] !== []): ?>
    <h2>Archivos y verificación (SHA-256)</h2>
    <table class="tabla">
        <tr><th>Archivo</th><th>Para</th><th>Tamaño</th><th>SHA-256</th></tr>
        <?php foreach ($app['apks'] as $apk): ?>
        <tr>
            <td><a href="<?= $h($apk['url']) ?>" rel="noopener"><?= $h($apk['archivo']) ?></a></td>
            <td><?= $h($descripcion_abi[$apk['abi']] ?? $apk['abi']) ?></td>
            <td><?= $h(judy_tamano_legible($apk['tamano_bytes'])) ?></td>
            <td class="sha"><?= $h($apk['sha256']) ?></td>
        </tr>
        <?php endforeach; ?>
    </table>
    <?php endif; ?>

    <div class="aviso">
        <strong>🔒 Descarga solo desde esta página o desde GitHub Releases</strong> del proyecto y
        <strong>verifica el SHA-256</strong> antes de instalar. Si no coincide, no instales el archivo.
        <ul style="margin-top:8px;">
            <li>Windows (PowerShell): <code>Get-FileHash .\archivo.apk -Algorithm SHA256</code></li>
            <li>macOS / Linux: <code>shasum -a 256 archivo.apk</code></li>
            <li>Android: apps como «Hash Droid» calculan el SHA-256 del archivo descargado.</li>
        </ul>
    </div>

    <h2>Cómo instalar</h2>
    <ol>
        <li>Descarga la APK desde el teléfono con Chrome (o pásala desde tu computadora).</li>
        <li>Abre el archivo desde la notificación de descarga o desde la app <em>Archivos</em>.</li>
        <li>Android te pedirá permitir <strong>«Instalar apps desconocidas»</strong> para Chrome o Archivos:
            pulsa <em>Configuración</em>, activa <em>Permitir de esta fuente</em> y vuelve atrás.
            (Ruta habitual: Ajustes → Apps → Acceso especial → Instalar apps desconocidas.)</li>
        <li>Pulsa <strong>Instalar</strong>. Si Google Play Protect muestra un aviso por ser una app que no viene
            de Play Store, elige <em>Más detalles → Instalar de todas formas</em> solo si verificaste el SHA-256.</li>
        <li>Al terminar, por seguridad, desactiva de nuevo «Instalar apps desconocidas».</li>
    </ol>

    <h2>Actualizaciones</h2>
    <p>Descarga la nueva versión desde esta página e instálala encima: tus datos se conservan porque todas las
       versiones se firman con la misma clave. Si Android indica que el paquete «entra en conflicto», desinstala la
       versión anterior y vuelve a iniciar sesión.</p>

    <h2>Requisitos y permisos</h2>
    <ul>
        <li><?= $h($app['android_minimo']) ?> o superior y conexión a internet.</li>
        <li>Único permiso: <strong>Internet</strong>. Sin publicidad, sin rastreo, sin acceso a ubicación, cámara ni contactos.</li>
        <li>La app incluye un <strong>modo demo</strong> con datos simulados para probarla sin cuenta.</li>
        <li>Lee el <a href="privacidad.php">aviso de privacidad</a>. Puedes eliminar tu cuenta desde la app o desde
            <a href="eliminar_cuenta.php">la web</a>.</li>
    </ul>
</main>

</body>
</html>

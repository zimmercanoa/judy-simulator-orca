<?php
// ============================================================
//  api/registro.php — POST {matricula, nombre, correo, telefono, password}
//  Crea un usuario 'pendiente' y notifica a la administración con el
//  mismo enlace de aprobación por token que procesar_registro.php.
//  csrf-exception: registro público sin sesión; la aprobación valida token.
// ============================================================
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/_bootstrap.php';

api_metodo(['POST']);
api_rate_limit($conexion, 'registro', api_ip(), 5, 3600);

$entrada   = api_entrada();
$matricula = api_texto($entrada, 'matricula', 20);
$nombre    = api_texto($entrada, 'nombre', 100);
$correo    = api_texto($entrada, 'correo', 100);
$telefono  = api_texto($entrada, 'telefono', 15);
$password  = isset($entrada['password']) && is_string($entrada['password']) ? $entrada['password'] : '';

if ($matricula === '' || $nombre === '' || $correo === '' || $password === '') {
    api_error(400, 'Matrícula, nombre, correo y contraseña son obligatorios.');
}
if (!preg_match('/^[A-Za-z0-9_-]{3,20}$/', $matricula)) {
    api_error(400, 'La matrícula solo admite letras, números, guion y guion bajo (3-20).');
}
if (!filter_var($correo, FILTER_VALIDATE_EMAIL)) {
    api_error(400, 'El correo no es válido.');
}
if ($telefono !== '' && !preg_match('/^[0-9 +()-]{7,15}$/', $telefono)) {
    api_error(400, 'El teléfono no es válido.');
}
if (strlen($password) < 8 || strlen($password) > 72) {
    api_error(400, 'La contraseña debe tener entre 8 y 72 caracteres.');
}

$password_hash = password_hash($password, PASSWORD_BCRYPT);
$rol_temporal  = 'por_asignar';
$estatus       = 'pendiente';
$token         = bin2hex(random_bytes(32));
$token_expira  = date('Y-m-d H:i:s', strtotime('+7 days'));

$stmt = $conexion->prepare(
    'INSERT INTO usuarios
        (matricula, nombre_completo, email, telefono, password, rol, estatus, token_aprobacion, token_expira_en)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
);
$stmt->bind_param('sssssssss',
    $matricula, $nombre, $correo, $telefono,
    $password_hash, $rol_temporal, $estatus, $token, $token_expira
);
try {
    $stmt->execute();
} catch (mysqli_sql_exception $e) {
    if ((int)$e->getCode() === 1062) {
        api_error(409, 'Esa matrícula ya está registrada.');
    }
    throw $e;
} finally {
    $stmt->close();
}

// Notificación a la administración (si falla, el registro ya quedó guardado)
$correo_enviado = false;
try {
    $link = APP_URL . '/aprobar.php?m=' . urlencode($matricula) . '&t=' . $token;
    $mail = api_mailer();
    $mail->addReplyTo($correo, $nombre);
    $mail->isHTML(true);
    $mail->Subject = 'Nueva solicitud de registro (app móvil) — JuDy Simulator';
    $mail->Body = "
        <div style='font-family: Arial, sans-serif; max-width: 600px; margin: auto;'>
            <h2 style='color: #0b132b;'>Nueva Solicitud de Cuenta (app móvil)</h2>
            <ul style='font-size: 16px; line-height: 1.8;'>
                <li><strong>Matrícula:</strong> " . htmlspecialchars($matricula, ENT_QUOTES, 'UTF-8') . "</li>
                <li><strong>Nombre:</strong> "    . htmlspecialchars($nombre, ENT_QUOTES, 'UTF-8')    . "</li>
                <li><strong>Correo:</strong> "    . htmlspecialchars($correo, ENT_QUOTES, 'UTF-8')    . "</li>
                <li><strong>Teléfono:</strong> "  . htmlspecialchars($telefono, ENT_QUOTES, 'UTF-8')  . "</li>
            </ul>
            <p><a href='" . htmlspecialchars($link, ENT_QUOTES, 'UTF-8') . "'
                  style='display:inline-block; padding:12px 20px; background:#f37021; color:#fff;
                         text-decoration:none; border-radius:5px; font-weight:bold;'>
                Revisar y aprobar solicitud</a></p>
            <p style='font-size:13px; color:#475569;'>El enlace vence en 7 días y solo puede usarse una vez.</p>
        </div>";
    $mail->AltBody = "Nueva solicitud de: $nombre ($matricula). Abre el enlace de aprobación para asignar el rol.";
    $mail->send();
    $correo_enviado = true;
} catch (\Throwable $e) {
    error_log('API registro: fallo al notificar por correo.');
}

api_responder(201, [
    'ok' => true,
    'mensaje' => 'Registro recibido. Gerencia debe aprobar tu cuenta antes de iniciar sesión.',
    'notificado' => $correo_enviado,
]);

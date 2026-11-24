<?php
// ============================================================
//  api/contacto.php — POST {nombre, correo, mensaje}
//  Envía el mensaje a la administración vía SMTP (PHPMailer).
//  csrf-exception: formulario público sin sesión; limitado por IP.
// ============================================================
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/_bootstrap.php';

api_metodo(['POST']);

$entrada = api_entrada();
$nombre  = api_texto($entrada, 'nombre', 100);
$correo  = api_texto($entrada, 'correo', 100);
$mensaje = api_texto($entrada, 'mensaje', 3000);

if ($nombre === '' || $correo === '' || $mensaje === '' || !filter_var($correo, FILTER_VALIDATE_EMAIL)) {
    api_error(400, 'Nombre, correo válido y mensaje son obligatorios.');
}

// 1 mensaje por minuto y 5 por hora por IP
api_rate_limit($conexion, 'contacto-min', api_ip(), 1, 60);
api_rate_limit($conexion, 'contacto-hora', api_ip(), 5, 3600);

try {
    $mail = api_mailer();
    $mail->addReplyTo($correo, $nombre);
    $mail->isHTML(true);
    $mail->Subject = 'Mensaje de contacto (app móvil) — JuDy Simulator';
    $mail->Body = "
        <div style='font-family: Arial, sans-serif; max-width: 600px; margin: auto;'>
            <h2 style='color: #0b132b;'>Nuevo mensaje desde la app móvil</h2>
            <p><strong>Nombre:</strong> " . htmlspecialchars($nombre, ENT_QUOTES, 'UTF-8') . "</p>
            <p><strong>Correo:</strong> " . htmlspecialchars($correo, ENT_QUOTES, 'UTF-8') . "</p>
            <p><strong>Mensaje:</strong></p>
            <blockquote style='border-left: 4px solid #f37021; padding-left: 12px; color: #333;'>
                " . nl2br(htmlspecialchars($mensaje, ENT_QUOTES, 'UTF-8')) . "
            </blockquote>
        </div>";
    $mail->AltBody = "Nombre: $nombre\nCorreo: $correo\nMensaje:\n$mensaje";
    $mail->send();
} catch (\Throwable $e) {
    error_log('API contacto: fallo al enviar correo.');
    api_error(502, 'No se pudo enviar el mensaje. Inténtalo más tarde.');
}

api_responder(200, ['ok' => true, 'mensaje' => 'Mensaje enviado. Te responderemos pronto.']);

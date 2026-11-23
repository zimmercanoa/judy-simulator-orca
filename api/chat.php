<?php
// ============================================================
//  api/chat.php — POST {mensaje} → {respuesta}
//  Proxy al asistente Gemini con las mismas restricciones de
//  confidencialidad que chat_api.php. Requiere token Bearer
//  (equivale a la sesión web) y limita 30 mensajes/hora por usuario.
//  csrf-exception: API sin cookies; autenticación por token Bearer.
// ============================================================
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/_bootstrap.php';
require_once __DIR__ . '/_gemini.php';

api_metodo(['POST']);
$usuario = api_requerir_usuario($conexion);

$entrada = api_entrada();
$mensaje = isset($entrada['mensaje']) && is_string($entrada['mensaje']) ? trim($entrada['mensaje']) : '';
if ($mensaje === '' || mb_strlen($mensaje) > 1000) {
    api_error(400, 'Escribe una pregunta de entre 1 y 1000 caracteres.');
}

api_rate_limit($conexion, 'chat', 'u' . $usuario['id_usuario'], 30, 3600);

$resultado = judy_chat_preguntar($mensaje);
if (!$resultado['ok']) {
    api_error(502, $resultado['error']);
}

api_responder(200, [
    'ok' => true,
    'respuesta' => $resultado['respuesta'],
    'configurado' => $resultado['configurado'],
]);

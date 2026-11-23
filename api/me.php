<?php
// ============================================================
//  api/me.php — GET con Bearer: datos públicos del usuario actual.
// ============================================================
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/_bootstrap.php';

api_metodo(['GET']);
$usuario = api_requerir_usuario($conexion);

api_responder(200, ['ok' => true, 'usuario' => api_usuario_publico($usuario)]);

<?php
// ============================================================
//  api/logout.php — POST con Bearer: revoca el token actual.
//  csrf-exception: API sin cookies; autenticación por token Bearer.
// ============================================================
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/_bootstrap.php';

api_metodo(['POST']);
$usuario = api_requerir_usuario($conexion);

$id_token = $usuario['id_token'];
$stmt = $conexion->prepare('DELETE FROM api_tokens WHERE id_token = ?');
$stmt->bind_param('i', $id_token);
$stmt->execute();
$stmt->close();

api_responder(200, ['ok' => true]);

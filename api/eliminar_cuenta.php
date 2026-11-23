<?php
// ============================================================
//  api/eliminar_cuenta.php — POST {password} con Bearer.
//  Elimina definitivamente la cuenta del usuario autenticado.
//  ON DELETE CASCADE borra también sus avances_vr y api_tokens.
//  Requisito de Google Play para apps con registro de cuentas.
//  csrf-exception: API sin cookies; autenticación por token Bearer
//  + confirmación con la contraseña actual.
// ============================================================
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/_bootstrap.php';

api_metodo(['POST']);
$usuario = api_requerir_usuario($conexion);
api_rate_limit($conexion, 'eliminar', 'u' . $usuario['id_usuario'], 5, 900);

$entrada  = api_entrada();
$password = isset($entrada['password']) && is_string($entrada['password']) ? $entrada['password'] : '';
if ($password === '') {
    api_error(400, 'Confirma con tu contraseña.');
}

$id_usuario = $usuario['id_usuario'];
$stmt = $conexion->prepare('SELECT password, rol FROM usuarios WHERE id_usuario = ? LIMIT 1');
$stmt->bind_param('i', $id_usuario);
$stmt->execute();
$fila = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$fila || !password_verify($password, $fila['password'])) {
    api_error(401, 'La contraseña no es correcta.');
}

// No dejar el sistema sin ninguna cuenta de gerencia aprobada
if ($fila['rol'] === 'gerencia') {
    $stmt = $conexion->prepare(
        "SELECT COUNT(*) AS total FROM usuarios
          WHERE rol = 'gerencia' AND estatus = 'aprobado' AND id_usuario <> ?"
    );
    $stmt->bind_param('i', $id_usuario);
    $stmt->execute();
    $otros = (int)($stmt->get_result()->fetch_assoc()['total'] ?? 0);
    $stmt->close();
    if ($otros === 0) {
        api_error(409, 'Eres la única cuenta de gerencia. Asigna otra cuenta de gerencia antes de eliminar la tuya.');
    }
}

$stmt = $conexion->prepare('DELETE FROM usuarios WHERE id_usuario = ?');
$stmt->bind_param('i', $id_usuario);
$stmt->execute();
$stmt->close();

api_responder(200, ['ok' => true, 'mensaje' => 'Tu cuenta y tus datos fueron eliminados.']);

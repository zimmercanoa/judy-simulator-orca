<?php
// ============================================================
//  api/usuarios.php — solo gerencia
//   GET  → lista de usuarios con estatus 'pendiente'.
//   POST → {id_usuario, accion: "aprobar"|"rechazar", rol: "empleado"|"gerencia"}
//          aprobar asigna rol e invalida el token de aprobación;
//          rechazar marca estatus 'rechazado' (no puede iniciar sesión).
//  csrf-exception: API sin cookies; autenticación por token Bearer.
// ============================================================
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/_bootstrap.php';

$metodo  = api_metodo(['GET', 'POST']);
$usuario = api_requerir_usuario($conexion, 'gerencia');

if ($metodo === 'GET') {
    $stmt = $conexion->prepare(
        "SELECT id_usuario, matricula, nombre_completo, email, telefono, rol, estatus
           FROM usuarios
          WHERE estatus = 'pendiente'
          ORDER BY id_usuario"
    );
    $stmt->execute();
    $resultado = $stmt->get_result();
    $pendientes = [];
    while ($fila = $resultado->fetch_assoc()) {
        $pendientes[] = [
            'id_usuario' => (int)$fila['id_usuario'],
            'matricula' => (string)$fila['matricula'],
            'nombre_completo' => (string)$fila['nombre_completo'],
            'email' => (string)$fila['email'],
            'telefono' => (string)$fila['telefono'],
            'rol' => (string)$fila['rol'],
            'estatus' => (string)$fila['estatus'],
        ];
    }
    $stmt->close();
    api_responder(200, ['ok' => true, 'usuarios' => $pendientes]);
}

$entrada    = api_entrada();
$id_usuario = (int)($entrada['id_usuario'] ?? 0);
$accion     = api_texto($entrada, 'accion', 20);
$rol        = api_texto($entrada, 'rol', 20);

if ($id_usuario <= 0 || !in_array($accion, ['aprobar', 'rechazar'], true)) {
    api_error(400, 'Datos inválidos.');
}

if ($accion === 'aprobar') {
    if ($rol !== 'empleado' && $rol !== 'gerencia') {
        api_error(400, 'El rol debe ser empleado o gerencia.');
    }
    $stmt = $conexion->prepare(
        "UPDATE usuarios
            SET estatus = 'aprobado', rol = ?, token_aprobacion = NULL, token_expira_en = NULL
          WHERE id_usuario = ? AND estatus = 'pendiente'"
    );
    $stmt->bind_param('si', $rol, $id_usuario);
} else {
    $stmt = $conexion->prepare(
        "UPDATE usuarios
            SET estatus = 'rechazado', token_aprobacion = NULL, token_expira_en = NULL
          WHERE id_usuario = ? AND estatus = 'pendiente'"
    );
    $stmt->bind_param('i', $id_usuario);
}
$stmt->execute();
$afectadas = $stmt->affected_rows;
$stmt->close();

if ($afectadas !== 1) {
    api_error(409, 'El usuario no existe o ya no está pendiente.');
}

api_responder(200, ['ok' => true, 'id_usuario' => $id_usuario, 'accion' => $accion]);

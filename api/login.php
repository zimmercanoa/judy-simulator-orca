<?php
// ============================================================
//  api/login.php — POST {matricula, password}
//  Devuelve un token Bearer (solo usuarios con estatus 'aprobado').
//  csrf-exception: API sin cookies; autenticación por token Bearer.
// ============================================================
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/_bootstrap.php';

api_metodo(['POST']);
api_rate_limit($conexion, 'login', api_ip(), 10, 900);

$entrada   = api_entrada();
$matricula = api_texto($entrada, 'matricula', 20);
$password  = isset($entrada['password']) && is_string($entrada['password']) ? $entrada['password'] : '';

if ($matricula === '' || $password === '' || strlen($password) > 200) {
    api_error(400, 'Matrícula y contraseña son obligatorias.');
}

$stmt = $conexion->prepare(
    'SELECT id_usuario, matricula, nombre_completo, rol, password, estatus
       FROM usuarios
      WHERE matricula = ?
      LIMIT 1'
);
$stmt->bind_param('s', $matricula);
$stmt->execute();
$fila = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$fila || !password_verify($password, $fila['password'])) {
    api_error(401, 'Matrícula o contraseña incorrectas.');
}
if ($fila['estatus'] !== 'aprobado') {
    api_error(403, 'Tu cuenta aún no ha sido aprobada por gerencia.');
}

// Limpieza oportunista de tokens vencidos del usuario
$id_usuario = (int)$fila['id_usuario'];
$stmt = $conexion->prepare('DELETE FROM api_tokens WHERE id_usuario = ? AND expira_en <= NOW()');
$stmt->bind_param('i', $id_usuario);
$stmt->execute();
$stmt->close();

// Token aleatorio: solo su hash SHA-256 se guarda en la BD.
// Las fechas se calculan en MySQL (NOW()) para no depender de la zona
// horaria de PHP, ya que la validación también usa NOW().
$token = bin2hex(random_bytes(32));
$hash  = hash('sha256', $token);
$dias  = API_TOKEN_TTL_DIAS;

$stmt = $conexion->prepare(
    'INSERT INTO api_tokens (id_usuario, token_hash, creado_en, expira_en)
     VALUES (?, ?, NOW(), DATE_ADD(NOW(), INTERVAL ? DAY))'
);
$stmt->bind_param('isi', $id_usuario, $hash, $dias);
$stmt->execute();
$id_token = (int)$conexion->insert_id;
$stmt->close();

$stmt = $conexion->prepare('SELECT expira_en FROM api_tokens WHERE id_token = ? LIMIT 1');
$stmt->bind_param('i', $id_token);
$stmt->execute();
$expira = (string)($stmt->get_result()->fetch_assoc()['expira_en'] ?? '');
$stmt->close();

api_responder(200, [
    'ok' => true,
    'token' => $token,
    'expira_en' => $expira,
    'usuario' => api_usuario_publico($fila),
]);

<?php
// ============================================================
//  api/_bootstrap.php — Utilidades comunes de la API REST JSON
//
//  Cada endpoint incluye primero ../config.php (crea $conexion)
//  y después este archivo. Aquí se definen:
//   - cabeceras JSON y CORS mínimo (solo orígenes configurados),
//   - lectura de cuerpo JSON o form-urlencoded,
//   - autenticación Bearer contra la tabla api_tokens (hash SHA-256),
//   - rate limiting por ventana fija en la tabla api_rate_limits.
//  Las funciones reciben la conexión de config.php como parámetro $db.
//  csrf-exception: API sin cookies; autenticación por token Bearer.
// ============================================================

// Duración de un token de sesión móvil
const API_TOKEN_TTL_DIAS = 30;

// Estados válidos de un avance (mismos que gestionar_avances.php)
const API_ESTADOS_AVANCE = ['En Progreso', 'Completado', 'Pendiente'];

header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');
header('Cache-Control: no-store');

// Cualquier excepción no controlada (p. ej. mysqli en PHP 8.1) se
// registra en el log y se responde como JSON genérico, sin detalles.
set_exception_handler(static function (\Throwable $e): void {
    error_log('API JuDy: ' . get_class($e) . ': ' . $e->getMessage());
    if (!headers_sent()) {
        http_response_code(500);
        header('Content-Type: application/json; charset=utf-8');
    }
    echo json_encode(['ok' => false, 'error' => 'Error interno del servidor.'], JSON_UNESCAPED_UNICODE);
});

// ------------------------------------------------------------
// CORS: las apps nativas no lo necesitan. Solo se habilita para
// orígenes listados en API_CORS_ORIGINS (config.php), p. ej. una
// compilación Flutter Web. Sin constante => ningún origen.
// ------------------------------------------------------------
$origen = $_SERVER['HTTP_ORIGIN'] ?? '';
if ($origen !== '' && defined('API_CORS_ORIGINS')) {
    $permitidos = array_filter(array_map('trim', explode(',', (string)API_CORS_ORIGINS)));
    if (in_array($origen, $permitidos, true)) {
        header('Access-Control-Allow-Origin: ' . $origen);
        header('Vary: Origin');
        header('Access-Control-Allow-Headers: Authorization, X-Api-Token, Content-Type');
        header('Access-Control-Allow-Methods: GET, POST, PUT, OPTIONS');
        header('Access-Control-Max-Age: 600');
    }
}
if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    http_response_code(204);
    exit();
}

/** Responde JSON y termina. */
function api_responder(int $http, array $datos): never
{
    http_response_code($http);
    echo json_encode($datos, JSON_UNESCAPED_UNICODE);
    exit();
}

/** Responde un error JSON uniforme: {"ok":false,"error":"..."} */
function api_error(int $http, string $mensaje): never
{
    api_responder($http, ['ok' => false, 'error' => $mensaje]);
}

/** Restringe los métodos HTTP aceptados por el endpoint. */
function api_metodo(array $permitidos): string
{
    $metodo = $_SERVER['REQUEST_METHOD'] ?? 'GET';
    if (!in_array($metodo, $permitidos, true)) {
        header('Allow: ' . implode(', ', $permitidos));
        api_error(405, 'Método no permitido.');
    }
    return $metodo;
}

/** Lee el cuerpo como JSON (o form-urlencoded como respaldo). */
function api_entrada(): array
{
    static $datos = null;
    if ($datos !== null) {
        return $datos;
    }
    $tipo = $_SERVER['CONTENT_TYPE'] ?? '';
    if (stripos($tipo, 'application/json') !== false) {
        $raw = file_get_contents('php://input', false, null, 0, 65536);
        $json = json_decode((string)$raw, true);
        if (!is_array($json)) {
            api_error(400, 'Cuerpo JSON inválido.');
        }
        $datos = $json;
    } else {
        $datos = $_POST;
    }
    return $datos;
}

/** Obtiene un campo de texto recortado de la entrada. */
function api_texto(array $entrada, string $campo, int $max = 255): string
{
    $valor = $entrada[$campo] ?? '';
    if (!is_string($valor) && !is_int($valor)) {
        return '';
    }
    $valor = trim((string)$valor);
    return mb_substr($valor, 0, $max);
}

/** IP del cliente (REMOTE_ADDR; no se confía en cabeceras falsificables). */
function api_ip(): string
{
    return (string)($_SERVER['REMOTE_ADDR'] ?? '0.0.0.0');
}

/**
 * Rate limiting por ventana fija. $identidad suele ser la IP o el id
 * de usuario. Responde 429 al superar $max peticiones en $ventana s.
 */
function api_rate_limit(mysqli $db, string $cubeta, string $identidad, int $max, int $ventana): void
{
    $clave = hash('sha256', $cubeta . '|' . $identidad);
    $ahora = time();

    $stmt = $db->prepare('SELECT ventana_inicio, contador FROM api_rate_limits WHERE clave = ? LIMIT 1');
    $stmt->bind_param('s', $clave);
    $stmt->execute();
    $fila = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if ($fila && ($ahora - (int)$fila['ventana_inicio']) < $ventana) {
        if ((int)$fila['contador'] >= $max) {
            $espera = $ventana - ($ahora - (int)$fila['ventana_inicio']);
            header('Retry-After: ' . max(1, $espera));
            api_error(429, 'Demasiadas solicitudes. Inténtalo más tarde.');
        }
        $stmt = $db->prepare('UPDATE api_rate_limits SET contador = contador + 1 WHERE clave = ?');
        $stmt->bind_param('s', $clave);
    } else {
        $stmt = $db->prepare(
            'INSERT INTO api_rate_limits (clave, ventana_inicio, contador) VALUES (?, ?, 1)
             ON DUPLICATE KEY UPDATE ventana_inicio = VALUES(ventana_inicio), contador = 1'
        );
        $stmt->bind_param('si', $clave, $ahora);
    }
    $stmt->execute();
    $stmt->close();
}

/** Extrae el token Bearer (Authorization o X-Api-Token como respaldo). */
function api_token_recibido(): string
{
    $cabecera = $_SERVER['HTTP_AUTHORIZATION']
        ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
        ?? '';
    if ($cabecera === '' && function_exists('getallheaders')) {
        foreach (getallheaders() as $nombre => $valor) {
            if (strcasecmp($nombre, 'Authorization') === 0) {
                $cabecera = $valor;
                break;
            }
        }
    }
    if (preg_match('/^Bearer\s+([A-Fa-f0-9]{64})$/', trim((string)$cabecera), $m)) {
        return strtolower($m[1]);
    }
    $alterno = $_SERVER['HTTP_X_API_TOKEN'] ?? '';
    if (is_string($alterno) && preg_match('/^[A-Fa-f0-9]{64}$/', $alterno)) {
        return strtolower($alterno);
    }
    return '';
}

/**
 * Exige un token válido y vigente de un usuario aprobado.
 * Devuelve ['id_usuario','matricula','nombre_completo','rol','id_token'].
 */
function api_requerir_usuario(mysqli $db, ?string $rol = null): array
{
    $token = api_token_recibido();
    if ($token === '') {
        api_error(401, 'Falta el token de autenticación.');
    }
    $hash = hash('sha256', $token);
    $stmt = $db->prepare(
        "SELECT t.id_token, u.id_usuario, u.matricula, u.nombre_completo, u.rol
           FROM api_tokens AS t
           INNER JOIN usuarios AS u ON u.id_usuario = t.id_usuario
          WHERE t.token_hash = ? AND t.expira_en > NOW() AND u.estatus = 'aprobado'
          LIMIT 1"
    );
    $stmt->bind_param('s', $hash);
    $stmt->execute();
    $usuario = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$usuario) {
        api_error(401, 'Sesión inválida o expirada. Inicia sesión de nuevo.');
    }
    if ($rol !== null && $usuario['rol'] !== $rol) {
        api_error(403, 'No tienes permisos para esta acción.');
    }

    $id_token = (int)$usuario['id_token'];
    $stmt = $db->prepare('UPDATE api_tokens SET ultimo_uso = NOW() WHERE id_token = ?');
    $stmt->bind_param('i', $id_token);
    $stmt->execute();
    $stmt->close();

    $usuario['id_usuario'] = (int)$usuario['id_usuario'];
    $usuario['id_token'] = $id_token;
    return $usuario;
}

/** Representación pública de un usuario (sin password ni tokens). */
function api_usuario_publico(array $u): array
{
    return [
        'id_usuario' => (int)$u['id_usuario'],
        'matricula' => (string)$u['matricula'],
        'nombre_completo' => (string)$u['nombre_completo'],
        'rol' => (string)$u['rol'],
    ];
}

/** Representación pública de un avance VR. */
function api_avance_publico(array $a): array
{
    $salida = [
        'id_avance' => (int)$a['id_avance'],
        'id_usuario' => (int)$a['id_usuario'],
        'modulo' => (string)$a['modulo'],
        'porcentaje' => (int)$a['porcentaje'],
        'estado' => (string)$a['estado'],
        'retroalimentacion' => $a['retroalimentacion'] !== null ? (string)$a['retroalimentacion'] : '',
    ];
    if (isset($a['nombre_completo'])) {
        $salida['nombre_completo'] = (string)$a['nombre_completo'];
        $salida['matricula'] = (string)$a['matricula'];
    }
    return $salida;
}

/** Crea un PHPMailer SMTP ya autenticado con la cuenta del sistema. */
function api_mailer(): \PHPMailer\PHPMailer\PHPMailer
{
    require_once __DIR__ . '/../assets/lib/PHPMailer/Exception.php';
    require_once __DIR__ . '/../assets/lib/PHPMailer/PHPMailer.php';
    require_once __DIR__ . '/../assets/lib/PHPMailer/SMTP.php';

    $mail = new \PHPMailer\PHPMailer\PHPMailer(true);
    $mail->isSMTP();
    $mail->Host       = MAIL_HOST;
    $mail->SMTPAuth   = true;
    $mail->Username   = MAIL_USER;
    $mail->Password   = MAIL_PASS;
    $mail->SMTPSecure = \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_STARTTLS;
    $mail->Port       = MAIL_PORT;
    $mail->CharSet    = 'UTF-8';
    $mail->setFrom(MAIL_USER, MAIL_FROM_NAME);
    $mail->addAddress(MAIL_USER);
    return $mail;
}

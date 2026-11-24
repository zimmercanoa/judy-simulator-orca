<?php
// ============================================================
//  api/avances.php
//   GET            → avances propios (empleado) o todos (gerencia).
//                    Gerencia puede filtrar con ?id_usuario=N.
//   POST | PUT     → solo gerencia: actualiza un avance existente
//                    {id_avance, porcentaje, estado, retroalimentacion}.
//  csrf-exception: API sin cookies; autenticación por token Bearer.
// ============================================================
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/_bootstrap.php';

$metodo  = api_metodo(['GET', 'POST', 'PUT']);
$usuario = api_requerir_usuario($conexion);
api_rate_limit($conexion, 'avances', 'u' . $usuario['id_usuario'], 120, 60);

$sql_base = 'SELECT a.id_avance, a.id_usuario, a.modulo, a.porcentaje, a.estado, a.retroalimentacion,
                    u.matricula, u.nombre_completo
               FROM avances_vr AS a
               INNER JOIN usuarios AS u ON u.id_usuario = a.id_usuario';

if ($metodo === 'GET') {
    $es_gerencia = $usuario['rol'] === 'gerencia';

    if ($es_gerencia && !isset($_GET['id_usuario'])) {
        $stmt = $conexion->prepare($sql_base . ' ORDER BY u.nombre_completo, a.id_avance');
    } else {
        $id = $es_gerencia ? (int)$_GET['id_usuario'] : $usuario['id_usuario'];
        if ($id <= 0) {
            api_error(400, 'id_usuario inválido.');
        }
        $stmt = $conexion->prepare($sql_base . ' WHERE a.id_usuario = ? ORDER BY a.id_avance');
        $stmt->bind_param('i', $id);
    }
    $stmt->execute();
    $resultado = $stmt->get_result();
    $avances = [];
    while ($fila = $resultado->fetch_assoc()) {
        $avances[] = api_avance_publico($fila);
    }
    $stmt->close();

    api_responder(200, ['ok' => true, 'avances' => $avances]);
}

// --- Escritura: solo gerencia ---------------------------------
if ($usuario['rol'] !== 'gerencia') {
    api_error(403, 'Solo gerencia puede modificar avances.');
}

$entrada    = api_entrada();
$id_avance  = (int)($entrada['id_avance'] ?? 0);
$porcentaje = isset($entrada['porcentaje']) && is_numeric($entrada['porcentaje']) ? (int)$entrada['porcentaje'] : -1;
$estado     = api_texto($entrada, 'estado', 50);
$retro      = api_texto($entrada, 'retroalimentacion', 2000);

if ($id_avance <= 0 || $porcentaje < 0 || $porcentaje > 100
    || !in_array($estado, API_ESTADOS_AVANCE, true)) {
    api_error(400, 'Datos inválidos: porcentaje 0-100 y estado En Progreso, Completado o Pendiente.');
}

// Verificar existencia antes de actualizar (affected_rows es 0 si no hay cambios)
$stmt = $conexion->prepare('SELECT id_avance FROM avances_vr WHERE id_avance = ? LIMIT 1');
$stmt->bind_param('i', $id_avance);
$stmt->execute();
$existe = $stmt->get_result()->fetch_assoc();
$stmt->close();
if (!$existe) {
    api_error(404, 'El avance no existe.');
}

$stmt = $conexion->prepare(
    'UPDATE avances_vr SET porcentaje = ?, estado = ?, retroalimentacion = ? WHERE id_avance = ?'
);
$stmt->bind_param('issi', $porcentaje, $estado, $retro, $id_avance);
$stmt->execute();
$stmt->close();

$stmt = $conexion->prepare($sql_base . ' WHERE a.id_avance = ? LIMIT 1');
$stmt->bind_param('i', $id_avance);
$stmt->execute();
$fila = $stmt->get_result()->fetch_assoc();
$stmt->close();

api_responder(200, ['ok' => true, 'avance' => api_avance_publico($fila)]);

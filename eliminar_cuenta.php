<?php
// ============================================================
//  eliminar_cuenta.php — El usuario autenticado elimina su cuenta.
//  POST + token CSRF + contraseña actual. ON DELETE CASCADE borra
//  sus avances_vr y api_tokens. Requisito de Google Play.
// ============================================================
session_start();
require_once __DIR__ . '/config.php';

if (!isset($_SESSION['id_usuario'])) {
    header('Location: login.php');
    exit();
}
if (empty($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}
$csrf_token = $_SESSION['csrf_token'];
$id_usuario = (int)$_SESSION['id_usuario'];
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $token    = $_POST['csrf_token'] ?? '';
    $password = $_POST['password'] ?? '';
    $confirma = isset($_POST['confirmo']);

    if (!is_string($token) || !hash_equals($csrf_token, $token)) {
        http_response_code(403);
        die('Token CSRF inválido.');
    }

    if (!$confirma || !is_string($password) || $password === '') {
        $error = 'Marca la casilla de confirmación y escribe tu contraseña.';
    } else {
        $stmt = $conexion->prepare('SELECT password, rol FROM usuarios WHERE id_usuario = ? LIMIT 1');
        $stmt->bind_param('i', $id_usuario);
        $stmt->execute();
        $fila = $stmt->get_result()->fetch_assoc();
        $stmt->close();

        if (!$fila || !password_verify($password, $fila['password'])) {
            $error = 'La contraseña no es correcta.';
        } else {
            $otros_gerentes = 1;
            if ($fila['rol'] === 'gerencia') {
                $stmt = $conexion->prepare(
                    "SELECT COUNT(*) AS total FROM usuarios
                      WHERE rol = 'gerencia' AND estatus = 'aprobado' AND id_usuario <> ?"
                );
                $stmt->bind_param('i', $id_usuario);
                $stmt->execute();
                $otros_gerentes = (int)($stmt->get_result()->fetch_assoc()['total'] ?? 0);
                $stmt->close();
            }

            if ($otros_gerentes === 0) {
                $error = 'Eres la única cuenta de gerencia. Asigna otra cuenta de gerencia antes de eliminar la tuya.';
            } else {
                $stmt = $conexion->prepare('DELETE FROM usuarios WHERE id_usuario = ?');
                $stmt->bind_param('i', $id_usuario);
                $stmt->execute();
                $stmt->close();

                session_unset();
                session_destroy();
                header('Location: index.php?cuenta=eliminada');
                exit();
            }
        }
    }
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Eliminar cuenta — JuDy Simulator</title>
    <link rel="stylesheet" href="assets/css/styles.css">
    <style>
        .login-container { display:flex; justify-content:center; padding:40px 20px; }
        .login-box       { background:var(--fondo-tarjeta); padding:40px; border-radius:12px;
                           border:1px solid var(--borde-color); width:100%; max-width:600px; }
        .input-group     { margin-bottom:20px; text-align:left; }
        .input-group input[type=password] { width:100%; padding:12px; border-radius:6px;
                           border:1px solid var(--borde-color); background:var(--fondo-principal);
                           color:var(--letras-principales); font-size:16px; }
        .btn-peligro     { background:#dc2626; color:#fff; border:none; padding:12px 20px;
                           border-radius:6px; font-weight:bold; cursor:pointer; width:100%; font-size:16px; }
    </style>
</head>
<body>

<?php $nav_tipo = 'panel'; include __DIR__ . '/navbar.php'; ?>

<div class="login-container">
    <div class="login-box">
        <h2 style="margin-bottom:15px; font-size:28px;">Eliminar mi cuenta</h2>
        <p style="color:var(--letras-secundarias); margin-bottom:15px;">
            Esta acción es <strong>permanente</strong>. Se borrarán tu matrícula, nombre, correo,
            teléfono, contraseña y todo tu historial de avances VR. Los mensajes enviados al
            asistente virtual no se guardan en nuestra base de datos.
        </p>
        <?php if ($error !== ''): ?>
            <p style="color:#dc2626; font-weight:bold; margin-bottom:20px;">
                <?= htmlspecialchars($error, ENT_QUOTES, 'UTF-8') ?>
            </p>
        <?php endif; ?>
        <form method="POST" action="eliminar_cuenta.php">
            <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf_token, ENT_QUOTES, 'UTF-8') ?>">
            <div class="input-group">
                <label for="password">Contraseña actual</label>
                <input type="password" id="password" name="password" required autocomplete="current-password">
            </div>
            <div class="input-group">
                <label><input type="checkbox" name="confirmo" value="1" required>
                    Entiendo que mi cuenta y mis datos se eliminarán definitivamente.</label>
            </div>
            <button type="submit" class="btn-peligro">Eliminar mi cuenta definitivamente</button>
        </form>
        <p style="margin-top:20px; font-size:14px;">
            <a href="seguimiento.php">Cancelar y volver al panel</a> ·
            <a href="privacidad.php">Aviso de privacidad</a>
        </p>
    </div>
</div>

</body>
</html>

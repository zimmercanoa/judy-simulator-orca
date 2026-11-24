<?php
// ============================================================
//  config.sample.php — Plantilla de configuración
//  Copia este archivo como "config.php" en la raíz pública del
//  servidor (alwaysdata: ~/www/ · InfinityFree: htdocs/) y completa
//  tus credenciales reales. config.php NUNCA se sube a Git ni por FTP.
//  Guía: DESPLIEGUE.md / DESPLIEGUE_ALWAYSDATA.md
// ============================================================

// --- Configuración de errores en producción -----------------
ini_set('display_errors', '0');
ini_set('display_startup_errors', '0');
error_reporting(0);

// --- Base de datos -------------------------------------------
// Opción A (recomendada) — alwaysdata (panel → Bases de datos → MySQL):
//   host     mysql-<cuenta>.alwaysdata.net
//   usuario  <cuenta>  (o un usuario adicional <cuenta>_xxx)
//   BD       <cuenta>_judyb   (alwaysdata antepone "<cuenta>_")
define('DB_HOST', 'mysql-CUENTA.alwaysdata.net');  // Reemplaza CUENTA por tu cuenta
define('DB_USER', 'CUENTA');
define('DB_PASS', 'TU_PASSWORD');                  // Contraseña del usuario MySQL
define('DB_NAME', 'CUENTA_judyb');
//
// Opción B — InfinityFree (respaldo; vPanel → MySQL Databases):
// define('DB_HOST', 'sql310.infinityfree.com');
// define('DB_USER', 'if0_43331816');
// define('DB_PASS', 'TU_PASSWORD_VPANEL');
// define('DB_NAME', 'if0_43331816_JuDyb');

// --- Correo (SMTP Gmail con contraseña de aplicación) --------
define('MAIL_HOST',     'smtp.gmail.com');
define('MAIL_PORT',     587);
define('MAIL_USER',     'tu_correo@gmail.com');
define('MAIL_PASS',     'tu_app_password_de_gmail');
define('MAIL_FROM_NAME','JuDy Simulator System');

// --- URL pública del sitio (sin barra final) ----------------
// alwaysdata: https://CUENTA.alwaysdata.net · InfinityFree: https://judysimulator.wuaze.com
define('APP_URL', 'https://CUENTA.alwaysdata.net');

// --- Chatbot con Gemini (solo servidor; NUNCA exponer al navegador) --
// Obtén tu clave en https://aistudio.google.com/app/apikey
// Cámbiala en config.php del servidor por tu clave real.
define('GEMINI_API_KEY', 'TU_GEMINI_API_KEY');
define('GEMINI_MODEL',   'gemini-3.8-flash');

// --- API REST móvil (api/) ----------------------------------
// Orígenes permitidos para CORS, separados por coma. Las apps nativas
// (Android/iOS) NO necesitan CORS; déjalo vacío salvo que publiques una
// compilación Flutter Web. Ejemplo: 'https://app.ejemplo.com'
define('API_CORS_ORIGINS', '');

// --- Conexión centralizada a la base de datos ---------------
if (!isset($conexion) || !($conexion instanceof mysqli)) {
    $conexion = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
    if ($conexion->connect_error) {
        error_log('Error de conexion MySQL: ' . $conexion->connect_error);
        die('Error de conexión a la base de datos.');
    }
    $conexion->set_charset('utf8mb4');
}

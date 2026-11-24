<?php
// ============================================================
//  privacidad.php — Aviso de privacidad (sitio web y app móvil).
//  Página pública: no requiere sesión ni base de datos.
// ============================================================
session_start();
$actualizado = '23 de noviembre de 2026';
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Aviso de privacidad — JuDy Simulator</title>
    <link rel="stylesheet" href="assets/css/styles.css">
    <style>
        .doc { max-width:900px; margin:0 auto; padding:50px 20px; line-height:1.7; }
        .doc h1 { font-size:36px; margin-bottom:10px; }
        .doc h2 { font-size:22px; margin:30px 0 10px; color:var(--letras-especiales); }
        .doc ul { margin-left:22px; }
        .doc p, .doc li { color:var(--letras-principales); margin-bottom:8px; }
        .doc table { width:100%; border-collapse:collapse; margin:10px 0; }
        .doc th, .doc td { border:1px solid var(--borde-color); padding:8px; text-align:left; vertical-align:top; }
        .doc th { background:var(--fondo-tarjeta); }
        .nota { color:var(--letras-secundarias); font-size:14px; }
    </style>
</head>
<body>

<?php $nav_tipo = 'publica'; include __DIR__ . '/navbar.php'; ?>

<main class="doc">
    <h1>Aviso de <span class="texto-naranja">privacidad</span></h1>
    <p class="nota">Última actualización: <?= htmlspecialchars($actualizado, ENT_QUOTES, 'UTF-8') ?>.
       Aplica al sitio web JuDy Simulator y a la aplicación móvil «JuDy Simulator» para Android.</p>

    <h2>1. Responsable</h2>
    <p>JuDy Simulator es un proyecto académico de capacitación en seguridad industrial con realidad
       virtual. Para cualquier asunto de privacidad usa el <a href="contacto.php">formulario de contacto</a>.</p>

    <h2>2. Datos que recabamos y para qué</h2>
    <table>
        <tr><th>Dato</th><th>Finalidad</th><th>¿Obligatorio?</th></tr>
        <tr><td>Matrícula y nombre completo</td><td>Identificarte, aprobar tu cuenta y mostrar tu progreso.</td><td>Sí</td></tr>
        <tr><td>Correo electrónico</td><td>Revisar tu solicitud de registro y responderte.</td><td>Sí</td></tr>
        <tr><td>Teléfono</td><td>Contacto opcional sobre tu capacitación.</td><td>No</td></tr>
        <tr><td>Contraseña</td><td>Autenticación. Se guarda solo como hash bcrypt; nadie puede leerla.</td><td>Sí</td></tr>
        <tr><td>Avances de capacitación VR (módulo, porcentaje, estado, retroalimentación)</td><td>Seguimiento de tu capacitación por parte de gerencia.</td><td>—</td></tr>
        <tr><td>Mensajes del formulario de contacto (nombre, correo, mensaje)</td><td>Responder tu consulta; se envían por correo al equipo.</td><td>Sí, si lo usas</td></tr>
        <tr><td>Preguntas al asistente virtual</td><td>Generar la respuesta. Ver punto 4.</td><td>Sí, si lo usas</td></tr>
    </table>
    <p>No recabamos ubicación, contactos, fotos, identificadores publicitarios ni datos de pago.
       La app no incluye publicidad ni herramientas de analítica o rastreo de terceros.</p>

    <h2>3. Datos técnicos</h2>
    <ul>
        <li>Para limitar abusos guardamos temporalmente un <strong>hash</strong> de la dirección IP junto con un contador de peticiones.</li>
        <li>Al iniciar sesión en la app se genera un token de sesión; en el servidor solo se almacena su hash y caduca a los 30 días o al cerrar sesión.
            En el teléfono el token se guarda cifrado (Android Keystore) y se borra al cerrar sesión.</li>
        <li>El sitio web usa una cookie de sesión técnica, necesaria para iniciar sesión. El proveedor de hosting puede usar cookies de seguridad propias.</li>
    </ul>

    <h2>4. Asistente virtual (Google Gemini)</h2>
    <p>Las preguntas que escribes al asistente se envían a la API de Google Gemini para generar la respuesta.
       No enviamos tu nombre, matrícula ni otros datos de tu cuenta, y no guardamos el historial de conversación en
       nuestra base de datos. <strong>No escribas datos personales en el chat.</strong> El tratamiento por parte de
       Google se rige por sus propios términos de la API.</p>

    <h2>5. Con quién compartimos datos</h2>
    <ul>
        <li><strong>Proveedor de hosting y base de datos</strong>, que almacena la información en sus servidores.</li>
        <li><strong>Google (Gmail SMTP)</strong>, para enviar los correos de registro y contacto.</li>
        <li><strong>Google (Gemini API)</strong>, solo el texto de tus preguntas al asistente.</li>
    </ul>
    <p>No vendemos ni cedemos tus datos a terceros con fines comerciales.</p>

    <h2>6. Seguridad</h2>
    <p>Toda la comunicación de la app viaja cifrada por HTTPS. Las contraseñas se almacenan con bcrypt, las consultas a la
       base de datos son parametrizadas y el acceso a la información de otros usuarios está restringido al rol de gerencia.</p>

    <h2>7. Conservación y eliminación de la cuenta</h2>
    <p>Conservamos tus datos mientras tu cuenta exista. Puedes eliminarla en cualquier momento y se borrarán
       definitivamente tu cuenta, tus avances VR y tus sesiones activas:</p>
    <ul>
        <li><strong>En la app:</strong> menú de tu cuenta → «Eliminar mi cuenta» (pide tu contraseña).</li>
        <li><strong>En la web:</strong> inicia sesión y entra a <a href="eliminar_cuenta.php">Eliminar mi cuenta</a>.</li>
        <li><strong>Sin acceso a tu cuenta:</strong> escríbenos desde el <a href="contacto.php">formulario de contacto</a>
            indicando tu matrícula; eliminaremos la cuenta en un máximo de 30 días tras verificar que eres el titular.</li>
    </ul>
    <p>Las solicitudes de registro rechazadas pueden eliminarse por la misma vía.</p>

    <h2>8. Tus derechos (ARCO)</h2>
    <p>Puedes solicitar el acceso, rectificación, cancelación u oposición al tratamiento de tus datos personales
       mediante el formulario de contacto, de acuerdo con la Ley Federal de Protección de Datos Personales en
       Posesión de los Particulares.</p>

    <h2>9. Menores de edad</h2>
    <p>La plataforma está dirigida a personal en capacitación laboral mayor de 18 años.</p>

    <h2>10. Cambios</h2>
    <p>Publicaremos cualquier cambio en esta página indicando la fecha de actualización.</p>
</main>

</body>
</html>

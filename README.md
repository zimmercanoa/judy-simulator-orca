# JuDy Simulator

Plataforma web PHP para capacitación en seguridad industrial con realidad virtual (NOM-009 / NOM-029). Incluye registro con aprobación por correo, roles `empleado` / `gerencia`, panel de avances VR y formulario de contacto.

## Estructura

- `*.php` — páginas públicas, panel y procesadores de formularios.
- `config.php` — credenciales reales (ignorado por Git; **no subir**).
- `config.sample.php` — plantilla sin secretos para crear `config.php`.
- `JuDyb.sql` — esquema MySQL (sin `CREATE DATABASE` ni `USE`; se importa igual en alwaysdata e InfinityFree).
- `sql/migracion_api_tokens.sql` — tablas de la API móvil.
- `assets/` — CSS, imágenes y PHPMailer.
- `GEMINI.md` — reglas obligatorias de producción.
- `.gemini/commands/` — comandos de auditoría y adaptación a InfinityFree.
- `asistente.php` / `asistente_api.php` — asistente virtual con Gemini (clave solo en `config.php`; sin acceso a datos personales).

## Desarrollo local

1. Importa `JuDyb.sql` en tu MySQL local (WAMP/XAMPP).
2. Copia `config.sample.php` a `config.php` y ajusta `DB_*` y `APP_URL`.
3. Verifica sintaxis con PHP 8.1 o superior:

   ```sh
   php -l *.php
   ```

> Guarda todos los `.php` en **UTF-8 sin BOM**. Un BOM antes de `<?php` envía salida antes de las cabeceras y rompe `header('Location: ...')` y `session_start()`.

## Despliegue

El sitio se publica desde `master` con GitHub Actions en dos hostings. Resumen y comparación en **[DESPLIEGUE.md](DESPLIEGUE.md)**.

- **alwaysdata (principal):** `https://CUENTA.alwaysdata.net` — sitio + API para la app móvil. Workflow `deploy-alwaysdata.yml`, guía paso a paso en [DESPLIEGUE_ALWAYSDATA.md](DESPLIEGUE_ALWAYSDATA.md).
- **InfinityFree (respaldo):** https://judysimulator.wuaze.com — solo web en navegador (su desafío anti-bots bloquea la app). Workflow `deploy.yml`, guía en [DESPLIEGUE_INFINITYFREE.md](DESPLIEGUE_INFINITYFREE.md).

En ambos: importa `JuDyb.sql` y `sql/migracion_api_tokens.sql`, crea `config.php` a mano en el servidor a partir de `config.sample.php` (nunca se sube a Git ni por FTP) y carga los secrets FTP en GitHub. La rama con la versión actual es `master`.

## Seguridad aplicada

- Contraseñas con `password_hash()` / `password_verify()`.
- Consultas preparadas y `$conexion` centralizada con `utf8mb4`.
- Aprobación por token con expiración de 7 días; el rol se elige mediante `POST`.
- Panel de gerencia con token CSRF y aprobación solo de usuarios pendientes.
- Validación de correo y límite de envíos en el formulario de contacto.
- Errores PHP ocultos y registrados en `error_log`.

## Antes de publicar

- Rota cualquier contraseña de Gmail que haya aparecido en chats o historiales y usa solo una contraseña de aplicación en `config.php`.
- Revisa los datos de prueba de `JuDyb.sql` (correos y teléfonos de ejemplo).

## App móvil y API REST

- [`mobile/`](mobile/README.md): app Flutter (Android/iOS) con login, registro, progreso VR, panel de gerencia, asistente, normas STPS y contacto. Incluye **modo demo** sin servidor.
- [`api/`](api/README.md): API REST JSON con tokens Bearer para la app. Requiere ejecutar una vez `sql/migracion_api_tokens.sql`.
- La app usa la API publicada en **alwaysdata** (`SITE_URL`); InfinityFree gratuito responde a las apps nativas con un desafío JavaScript anti-bots. Detalles en [`mobile/README.md`](mobile/README.md).
- APK: se descarga desde `descargar.php`; se compila y publica en GitHub Releases con el workflow `build-apk.yml` al crear un tag `mobile-vX.Y.Z` ([guía](mobile/store/DISTRIBUCION_APK.md)).
- Privacidad y eliminación de cuenta: `privacidad.php`, `eliminar_cuenta.php` y `api/eliminar_cuenta.php`.

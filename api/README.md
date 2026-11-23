# API REST JSON — JuDy Simulator

API mínima para la app móvil (`../mobile`). PHP 8.1, `mysqli` con consultas
preparadas y la conexión `$conexion` de `config.php` (no se crea otra).

## Instalación

1. Ejecuta una vez [`../sql/migracion_api_tokens.sql`](../sql/migracion_api_tokens.sql)
   en phpMyAdmin (crea `api_tokens` y `api_rate_limits`; sin `CREATE DATABASE`/`USE`).
2. Sube la carpeta `api/` junto al resto del sitio (el workflow de despliegue ya
   la incluye; excluye `mobile/` y `sql/`).
3. Opcional: define `API_CORS_ORIGINS` en `config.php` (ver `config.sample.php`)
   solo si publicas una compilación Flutter Web. Las apps nativas no usan CORS.

> ⚠️ En InfinityFree gratuito las peticiones de apps nativas reciben un desafío
> JavaScript anti-bots en vez de JSON. Ver `../mobile/README.md` → *Hallazgo*.

## Diseño

- **Tokens:** `login.php` genera 32 bytes aleatorios (`bin2hex(random_bytes(32))`);
  en la BD solo se guarda `sha256(token)` con expiración de 30 días. Cada petición
  autenticada vuelve a comprobar que el usuario siga con `estatus = 'aprobado'`.
- **Rate limiting:** ventana fija en `api_rate_limits` (clave = `sha256(cubeta|IP o usuario)`),
  responde `429` + `Retry-After`.
- **Errores:** siempre JSON; las excepciones no controladas se registran con
  `error_log` y se devuelve un `500` genérico sin detalles internos.
- **Chat:** `_gemini.php` replica el *system prompt* de confidencialidad y el
  filtro de salida de `asistente_api.php`. Si cambias uno, actualiza el otro.
- **Nombres:** ningún endpoint contiene «chat»: InfinityFree responde 403 a cualquier
  URL con esa palabra (por eso el asistente es `asistente.php`).
- **Eliminar cuenta:** `eliminar_cuenta.php` pide la contraseña actual; `ON DELETE CASCADE`
  borra avances y tokens. No permite borrar la última cuenta de gerencia.
- **Versión:** `version.php` lee `descargas/app.json` (lo usa la app para avisar de actualizaciones).
- **Rechazar usuario:** marca `estatus = 'rechazado'` (no puede iniciar sesión).
- Los archivos con prefijo `_` están bloqueados por `.htaccess`, que además
  reenvía la cabecera `Authorization` cuando PHP corre como CGI/FPM.

## Ejemplos

```bash
API=https://tu-servidor.com/api
TOKEN=$(curl -s -X POST $API/login.php -H 'Content-Type: application/json' \
  -d '{"matricula":"EMP-001","password":"..."}' | jq -r .token)

curl -s $API/avances.php -H "Authorization: Bearer $TOKEN"
curl -s -X POST $API/logout.php -H "Authorization: Bearer $TOKEN"
```

Endpoints y cuerpos: ver la tabla en `../mobile/README.md`.

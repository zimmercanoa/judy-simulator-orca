# Despliegue en alwaysdata — JuDy Simulator (sitio + API + BD)

alwaysdata (plan gratuito) sirve el sitio completo **sin el desafío anti-bots
JavaScript** de InfinityFree, así que la app móvil puede usar la API JSON.
InfinityFree se mantiene como respaldo (`DESPLIEGUE_INFINITYFREE.md`).

En esta guía, **`CUENTA`** es el nombre de cuenta que elijas en alwaysdata
(también será el subdominio: `https://CUENTA.alwaysdata.net`).
**Ninguna contraseña se guarda en el repositorio.**

## 0. Lo que necesitas

- Acceso de administrador al repo `zimmercanoa/judy-simulator-orca` (para los secrets).
- La contraseña de aplicación de Gmail y la clave de Gemini (las mismas de InfinityFree, o nuevas).

## 1. Crear la cuenta (una vez)

1. Regístrate en https://www.alwaysdata.com y elige el plan **gratuito**.
2. Nombre de la cuenta: `CUENTA` (minúsculas). El sitio quedará en `https://CUENTA.alwaysdata.net`.
3. En el panel (https://admin.alwaysdata.com):
   - **Web → Sitios**: el sitio por defecto apunta a `CUENTA.alwaysdata.net`, tipo *PHP*, raíz `/www/`.
     Activa **Forzar HTTPS** en la configuración del sitio.
   - **Entorno → PHP**: selecciona PHP **8.1 o superior**.

## 2. Base de datos MySQL (una vez)

1. **Bases de datos → MySQL → Añadir una base de datos**: nombre `judyb`
   (alwaysdata le antepone la cuenta: queda **`CUENTA_judyb`**). Concede permisos al usuario `CUENTA`
   o crea un usuario dedicado (`CUENTA_judy`) en **Bases de datos → MySQL → Usuarios**.
2. Datos de conexión:

   | Dato | Valor |
   |---|---|
   | Host | `mysql-CUENTA.alwaysdata.net` |
   | Usuario | `CUENTA` (o `CUENTA_judy`) |
   | Base de datos | `CUENTA_judyb` |
   | phpMyAdmin | https://phpmyadmin.alwaysdata.com |

3. En phpMyAdmin selecciona `CUENTA_judyb` → **Importar**, en este orden:
   1. `JuDyb.sql` (tablas `usuarios` y `avances_vr` con datos de ejemplo).
   2. `sql/migracion_api_tokens.sql` (tablas `api_tokens` y `api_rate_limits` para la app).

   Ambos archivos no usan `CREATE DATABASE` ni `USE`, por lo que se importan sin cambios.
   Si vienes de InfinityFree con usuarios reales, exporta allí `usuarios` y `avances_vr`
   desde su phpMyAdmin e impórtalos aquí en lugar de los datos de ejemplo.
4. Los usuarios de ejemplo `GER-001` / `EMP-001` tienen la contraseña `12345`:
   cámbiala o elimínalos antes de abrir el sitio al público.

## 3. Acceso FTP (una vez)

**Acceso remoto → FTP**: usa el usuario de la cuenta (o crea uno adicional
limitado a `/www/`) y define su contraseña.

| Dato | Valor |
|---|---|
| Servidor | `ftp-CUENTA.alwaysdata.net` |
| Usuario | `CUENTA` (o el usuario FTP adicional) |
| Protocolo | FTPS (FTP sobre TLS), puerto 21 |
| Carpeta del sitio | `www/` |

## 4. `config.php` en el servidor (una vez, a mano)

1. Copia `config.sample.php` como `config.php` y súbelo a `www/` con un cliente
   FTPS (FileZilla) o por SSH. **Nunca** lo subas a Git; el workflow lo excluye.
2. Completa:

   ```php
   define('DB_HOST', 'mysql-CUENTA.alwaysdata.net');
   define('DB_USER', 'CUENTA');
   define('DB_PASS', '...');            // contraseña del usuario MySQL
   define('DB_NAME', 'CUENTA_judyb');
   define('MAIL_USER', 'tu_correo@gmail.com');
   define('MAIL_PASS', '...');          // contraseña de aplicación de Gmail
   define('APP_URL', 'https://CUENTA.alwaysdata.net');
   define('GEMINI_API_KEY', '...');
   define('API_CORS_ORIGINS', '');      // la app nativa no necesita CORS
   ```

3. Si el envío por Gmail (puerto 587) fallara, alwaysdata ofrece su propio SMTP
   (`smtp-CUENTA.alwaysdata.net`, ver *Correos* en el panel): cambia `MAIL_HOST` y las credenciales.

## 5. Secrets de GitHub para el despliegue automático (una vez)

En https://github.com/zimmercanoa/judy-simulator-orca/settings/secrets/actions:

| Tipo | Nombre | Valor |
|---|---|---|
| Secret | `ALWAYSDATA_FTP_SERVER` | `ftp-CUENTA.alwaysdata.net` |
| Secret | `ALWAYSDATA_FTP_USER` | `CUENTA` |
| Secret | `ALWAYSDATA_FTP_PASSWORD` | contraseña FTP |
| Variable (opcional) | `ALWAYSDATA_SERVER_DIR` | `www/` (valor por defecto) |
| Variable | `SITE_URL` | `https://CUENTA.alwaysdata.net` (la usa la compilación de la APK) |

Mientras falten los secrets, `deploy-alwaysdata.yml` termina en verde sin desplegar (avisa con una nota).

## 6. Primer despliegue

1. Fusiona la rama en `master` (o ve a **Actions → Despliegue a alwaysdata → Run workflow**).
2. El workflow sube el sitio a `www/` por FTPS con las mismas exclusiones que el de
   InfinityFree (`config.php`, `mobile/`, `sql/`, `*.md`, `.github/`…). `deploy.yml`
   sigue desplegando a InfinityFree en paralelo.

## 7. Probar

```bash
SITE=https://CUENTA.alwaysdata.net

# Sitio y páginas nuevas (esperado: 200 text/html, SIN "aes.js")
curl -s -o /dev/null -w "%{http_code} %{content_type}\n" $SITE/
curl -s $SITE/ | grep -c aes.js          # esperado: 0
curl -s -o /dev/null -w "%{http_code}\n" $SITE/descargar.php
curl -s -o /dev/null -w "%{http_code}\n" $SITE/privacidad.php

# API (esperado: JSON)
curl -s $SITE/api/version.php
curl -s -X POST $SITE/api/login.php -H 'Content-Type: application/json' \
     -d '{"matricula":"EMP-001","password":"12345"}'
# -> {"ok":true,"token":"...","usuario":{...}}
TOKEN=...   # pega el token
curl -s $SITE/api/me.php       -H "Authorization: Bearer $TOKEN"
curl -s $SITE/api/avances.php  -H "Authorization: Bearer $TOKEN"
curl -s -X POST $SITE/api/logout.php -H "Authorization: Bearer $TOKEN"

# Monitor del proyecto
python tools/judy_monitor.py --url $SITE
```

Si `me.php` responde *Falta el token* aunque envíes la cabecera, el servidor
está descartando `Authorization`: `api/.htaccess` ya la reenvía; como respaldo
la app y la API aceptan también la cabecera `X-Api-Token: <token>`.

## 8. App móvil apuntando a alwaysdata

- Compilación local: `flutter run --dart-define=SITE_URL=https://CUENTA.alwaysdata.net`
- APK publicada: define la variable `SITE_URL` (paso 5) y crea el tag `mobile-vX.Y.Z`;
  ver `mobile/store/DISTRIBUCION_APK.md`.
- Sin `SITE_URL`, la app usa el marcador `https://CUENTA.alwaysdata.net` y arranca en **modo demo**.

## Seguridad

- Rota cualquier contraseña que se haya compartido por chat antes de cargarla.
- Usa un usuario FTP adicional limitado a `www/` para el despliegue si puedes.
- No pegues credenciales en issues, PRs ni commits.

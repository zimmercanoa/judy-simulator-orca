# JuDy Simulator — App móvil (Flutter)

App Android/iOS de **JuDy Simulator**, la plataforma de capacitación en realidad
virtual para la instalación segura de paneles fotovoltaicos según las normas
STPS **NOM-009** (trabajos en altura) y **NOM-029** (mantenimiento eléctrico).

Consume la API REST JSON de la carpeta [`../api`](../api) y puede usarse sin
servidor en **modo demo**.

## Pantallas

| Pantalla | Descripción |
| --- | --- |
| Splash | Logo y restauración de la sesión guardada. |
| Login | Matrícula + contraseña (solo cuentas aprobadas), acceso al modo demo. |
| Registro | Solicitud de cuenta; queda *pendiente* hasta que gerencia la apruebe. |
| Mi progreso (empleado) | Avance general y tarjeta por módulo VR con barra, estado y retroalimentación. |
| Gerencia | Pestaña *Solicitudes* (aprobar con rol empleado/gerencia o rechazar) y *Avances VR* (editar porcentaje, estado y retroalimentación). |
| Asistente | Chat con el asistente virtual (Gemini a través del servidor, con la misma restricción de datos personales que la web). |
| Normas | Resumen de NOM-009-STPS-2011 y NOM-029-STPS-2011. |
| Contacto | Formulario que se envía por correo desde el servidor y enlace al portal web. |

Material 3, tema claro/oscuro con la paleta de `assets/css/styles.css`
(naranja `#F37021`, azul marino `#0B132B`, `#1C2541`, `#4EA8DE`) y los logos de
`assets/img`.

## Requisitos

- Flutter estable (probado con 3.47.4 / Dart 3.13).
- Android SDK para compilar el APK (o Xcode para iOS).

## Ejecutar

```bash
cd mobile
flutter pub get

# Modo demo (sin servidor, datos simulados)
flutter run --dart-define=DEMO_MODE=true

# Contra una API real
flutter run --dart-define=API_BASE_URL=https://tu-servidor.com/api

# APK de depuración
flutter build apk --debug --dart-define=API_BASE_URL=https://tu-servidor.com/api
```

| `--dart-define` | Valor por defecto | Uso |
| --- | --- | --- |
| `API_BASE_URL` | `https://judysimulator.wuaze.com/api` | URL de la carpeta `api/` (sin barra final). |
| `DEMO_MODE` | `false` | `true` arranca siempre en modo demo. |
| `WEB_URL` | `https://judysimulator.wuaze.com` | Portal web que abre el botón de Contacto. |

Aunque no se pase `DEMO_MODE`, la pantalla de login tiene los botones
**Empleado / Gerencia** y el interruptor *Usar datos simulados*.
Usuarios demo: `EMP-001` o `GER-001`, contraseña `demo1234`.

## Seguridad

- El token Bearer se guarda en `flutter_secure_storage` (Keychain en iOS,
  almacenamiento cifrado en Android). En el servidor solo se guarda su hash
  SHA-256 (`api_tokens`), con caducidad de 30 días; *Cerrar sesión* lo revoca.
- Si la API responde `401`, la app borra el token y vuelve al login.
- La app no incluye credenciales ni claves (la clave de Gemini vive solo en
  `config.php` del servidor).

## ⚠️ Hallazgo: InfinityFree bloquea las apps nativas

**Prueba (2026-11-23)** con `curl` contra el hosting actual:

```text
$ curl -i -A "Dart/3.13 (dart:io)" https://judysimulator.wuaze.com/
HTTP/1.1 200 OK
Server: openresty
Content-Type: text/html

<html><body><script type="text/javascript" src="/aes.js"></script><script>…
document.cookie="__test="+toHex(slowAES.decrypt(c,2,a,b))+"; …";
location.href="https://judysimulator.wuaze.com/?i=1";</script>
<noscript>This site requires Javascript to work…</noscript></body></html>
```

Lo mismo ocurre con `POST /api/login.php` y `POST /chat_api.php`: en lugar del
JSON, el plan gratuito de InfinityFree devuelve un **desafío anti-bots en
JavaScript** (`aes.js` + cookie `__test`). Un navegador lo resuelve solo; un
cliente HTTP nativo (Dart `http`, Retrofit, URLSession, curl…) no ejecuta
JavaScript, así que **la API no es utilizable desde la app mientras esté en
InfinityFree gratuito**. InfinityFree lo documenta como limitación del plan
gratuito: solo admite tráfico de navegadores.

La app lo detecta (`HttpJudyApi.esDesafioAntiBot`) y muestra un mensaje claro
con el botón **Usar modo demo**, en lugar de fallar con un error de JSON.

### Opciones

1. **Publicar la API en otro hosting (recomendado).** La carpeta `api/` es PHP
   8.1 sin dependencias nuevas; funciona en cualquier hosting PHP + MySQL sin
   protección anti-bots: un plan de pago (InfinityFree Premium/iFastNet,
   Hostinger, etc.), un VPS pequeño, o Render/Railway/Fly.io con un contenedor
   PHP-Apache. Pasos:
   1. Subir el sitio (o solo `config.php`, `assets/lib/PHPMailer` y `api/`).
   2. Ejecutar `JuDyb.sql` y `sql/migracion_api_tokens.sql` en la BD (o apuntar
      `config.php` a la BD remota si el proveedor permite conexiones externas;
      InfinityFree **no** las permite, así que habría que migrar los datos).
   3. Compilar la app con `--dart-define=API_BASE_URL=https://nuevo-host/api`.
2. **WebView como respaldo.** Mostrar el sitio web dentro de la app con
   `webview_flutter`: el WebView ejecuta JavaScript y supera el desafío, pero
   se pierde la experiencia nativa (se usarían las páginas PHP con sesión) y la
   API JSON seguiría sin poder usarse. Hoy la app ofrece el botón *Abrir portal
   web* en Contacto, que abre el navegador del sistema.
3. **No recomendado:** calcular la cookie `__test` imitando `aes.js` dentro de
   la app. Es frágil (InfinityFree cambia las claves), viola los términos del
   hosting y puede bloquear la cuenta.

Mientras no se migre la API, la app queda **plenamente funcional en modo demo**.

## API REST (resumen)

Todas las respuestas son JSON `{"ok": true, …}` o `{"ok": false, "error": "…"}`.
Autenticación: `Authorization: Bearer <token>` (respaldo: cabecera `X-Api-Token`).

| Método | Endpoint | Rol | Cuerpo / parámetros |
| --- | --- | --- | --- |
| POST | `login.php` | público | `{matricula, password}` → `{token, expira_en, usuario}` |
| POST | `logout.php` | autenticado | — |
| GET | `me.php` | autenticado | — |
| GET | `avances.php` | autenticado | propios; gerencia: todos o `?id_usuario=N` |
| POST/PUT | `avances.php` | gerencia | `{id_avance, porcentaje, estado, retroalimentacion}` |
| GET | `usuarios.php` | gerencia | solicitudes pendientes |
| POST | `usuarios.php` | gerencia | `{id_usuario, accion: aprobar\|rechazar, rol}` |
| POST | `registro.php` | público | `{matricula, nombre, correo, telefono, password}` |
| POST | `chat.php` | autenticado | `{mensaje}` → `{respuesta}` |
| POST | `contacto.php` | público | `{nombre, correo, mensaje}` |

Límites (por IP o usuario): login 10/15 min, registro 5/h, contacto 1/min y
5/h, chat 30/h, avances 120/min. Detalles en [`../api/README.md`](../api/README.md).

## Pruebas

```bash
flutter analyze
flutter test
```

Las pruebas cubren modelos, validadores, el cliente HTTP (con `MockClient`,
incluida la detección del desafío de InfinityFree), el modo demo, la sesión y
un recorrido de widgets splash → login → dashboard.

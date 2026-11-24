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
flutter run --dart-define=SITE_URL=https://CUENTA.alwaysdata.net

# APK de depuración
flutter build apk --debug --dart-define=SITE_URL=https://CUENTA.alwaysdata.net
```

| `--dart-define` | Valor por defecto | Uso |
| --- | --- | --- |
| `SITE_URL` | `https://CUENTA.alwaysdata.net` (**marcador**) | Sitio PHP en alwaysdata; la API es `SITE_URL/api`. Reemplaza `CUENTA` por la cuenta real. |
| `API_BASE_URL` | `SITE_URL/api` | Solo si la API vive en otro sitio (sin barra final). |
| `DEMO_MODE` | `false` | `true` arranca siempre en modo demo. |

Mientras `SITE_URL` siga siendo el marcador, la app arranca en **modo demo** y
los enlaces de privacidad/descarga abren el sitio de respaldo
(`judysimulator.wuaze.com`), que funciona en navegadores. Para no tener que
pasar el `--dart-define`, también puedes editar el valor por defecto en
`lib/config.dart`. En GitHub Actions se toma de la variable `SITE_URL`.

Aunque no se pase `DEMO_MODE`, la pantalla de login tiene los botones
**Empleado / Gerencia** y el interruptor *Usar datos simulados*.
Usuarios demo: `EMP-001` o `GER-001`, contraseña `demo1234`.

## Distribución

La APK se descarga desde `descargar.php` del sitio (alwaysdata o el respaldo en InfinityFree) y se
aloja en GitHub Releases (tag `mobile-vX.Y.Z`). Pasos para compilar, firmar y
publicar: [store/DISTRIBUCION_APK.md](store/DISTRIBUCION_APK.md). Medidas de
seguridad y opciones: [store/SEGURIDAD.md](store/SEGURIDAD.md).

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

Lo mismo ocurre con `POST /api/login.php` y `GET /api/version.php`: en lugar del
JSON, el plan gratuito de InfinityFree devuelve un **desafío anti-bots en
JavaScript** (`aes.js` + cookie `__test`). Un navegador lo resuelve solo; un
cliente HTTP nativo (Dart `http`, Retrofit, URLSession, curl…) no ejecuta
JavaScript, así que **la API no es utilizable desde la app mientras esté en
InfinityFree gratuito**. InfinityFree lo documenta como limitación del plan
gratuito: solo admite tráfico de navegadores.

**¿Ayuda cambiar el User-Agent?** No. Prueba del 2026-11-23 contra
`/api/version.php`:

| User-Agent | Resultado |
| --- | --- |
| `curl/8.0` (por defecto de curl) | conexión cortada (código `000`) y cuerpo con el desafío |
| `Dart/3.13 (dart:io)` (el de la app) | `200 text/html` con el desafío `aes.js` / `__test` |
| Chrome Android (`Mozilla/5.0 … Mobile Safari/537.36`) | `200 text/html` con el mismo desafío |

Un User-Agent de navegador solo evita el corte del UA de curl, pero **el desafío
de la cookie `__test` aparece igual**, así que la app no finge ser un navegador.
Además InfinityFree responde **403 a cualquier URL que contenga «chat»**, por eso
el endpoint del asistente es `api/asistente.php`.

La app lo detecta (`HttpJudyApi.esDesafioAntiBot`) y muestra un mensaje claro
con el botón **Usar modo demo**, en lugar de fallar con un error de JSON.

### Decisión: sitio completo en alwaysdata

El dueño eligió publicar el sitio completo (web + `api/` + BD) en **alwaysdata**
(plan gratuito, sin desafío JavaScript) y dejar InfinityFree como respaldo web.
La app usa `SITE_URL=https://CUENTA.alwaysdata.net`. Pasos:
[`../DESPLIEGUE_ALWAYSDATA.md`](../DESPLIEGUE_ALWAYSDATA.md). Sin WebView.

Alternativas descartadas: WebView del sitio (se pierde la app nativa y la API
seguiría inaccesible) y calcular la cookie `__test` imitando `aes.js` (frágil y
contrario a los términos del hosting).

Mientras no haya `SITE_URL`, la app queda **plenamente funcional en modo demo**.

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
| POST | `asistente.php` | autenticado | `{mensaje}` → `{respuesta}` |
| POST | `eliminar_cuenta.php` | autenticado | `{password}` — borra la cuenta y sus datos |
| GET | `version.php` | público | última versión publicada de la APK |
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

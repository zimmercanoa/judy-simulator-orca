# Distribución directa de la APK (sin Google Play)

La app se distribuye como APK descargable desde
**https://judysimulator.wuaze.com/descargar.php**. Los archivos viven en
**GitHub Releases** de `zimmercanoa/judy-simulator-orca` (tag `mobile-vX.Y.Z`),
no en el repositorio ni en InfinityFree: el plan gratuito limita el tamaño de
los archivos (~10 MB) y prohíbe usar el hosting para descargas.

```text
descargar.php ──lee──> descargas/app.json (versión, tamaño, SHA-256, URL)
      │                         ▲
      └──enlace──> GitHub Release mobile-v0.1.0 (APK + SHA256SUMS.txt)
api/version.php ──lee──> descargas/app.json ──> aviso "nueva versión" en la app
```

## 1. Herramientas (una sola vez)

- Flutter 3.47.4 (la misma versión que usa la CI).
- Android Studio (incluye Android SDK y el JDK 17 con `keytool`). Tras instalarlo:
  `flutter doctor --android-licenses`.
- GitHub CLI con sesión: `gh auth login`.

## 2. Clave de firma (una sola vez) — ¡CRÍTICO!

Android solo instala una actualización encima de la versión anterior si ambas
están firmadas con **la misma clave**. Si se pierde el keystore, los usuarios
tendrán que desinstalar la app (y volver a iniciar sesión) para instalar la
siguiente versión.

```powershell
cd mobile
.\store\scripts\generar_keystore.ps1 -Destino "$env:USERPROFILE\judy-claves\judy-release.jks"
```

- El keystore se guarda **fuera del repositorio** (el script se niega a crearlo dentro).
- El script crea `mobile/android/key.properties` (en `.gitignore`). Plantilla:
  `mobile/android/key.properties.example`.
- **Respaldo obligatorio:** copia el `.jks` y la contraseña en dos sitios seguros
  (gestor de contraseñas + unidad cifrada/USB). Nunca por correo ni en el repo.
- `.gitignore` bloquea `*.jks`, `*.keystore`, `key.properties`, `*.p12`.

## 3. Publicar una versión

1. Sube la versión en **tres** sitios (la prueba `test/version_test.dart` falla si no coinciden):
   - `mobile/pubspec.yaml` → `version: 0.2.0+2` (el número tras `+` siempre debe aumentar).
   - `mobile/lib/config.dart` → `appVersion` y `appVersionCode`.
   - `descargas/app.json` lo reescribe el script del paso 2.
2. Compila, calcula SHA-256 y actualiza `descargas/app.json`:

   ```powershell
   cd mobile
   .\store\scripts\publicar_release.ps1 -Notas "Qué cambió en esta versión" `
       -ApiBaseUrl "https://judysimulator.wuaze.com/api"   # o el hosting de la API
   ```

   Equivale a:

   ```bash
   flutter build apk --release --split-per-abi --obfuscate \
     --split-debug-info=%USERPROFILE%/judy-simbolos/0.1.0 \
     --dart-define=API_BASE_URL=https://…/api
   ```

   Genera `build/dist/<versión>/judy-simulator-<versión>-{arm64-v8a,armeabi-v7a,x86_64}.apk`
   y `SHA256SUMS.txt`. Los símbolos de depuración quedan en
   `%USERPROFILE%\judy-simbolos\<versión>` (respáldalos: sin ellos no se pueden
   leer los errores de una APK ofuscada).
3. Publica el release (el script imprime el comando exacto; con `-Publicar` lo ejecuta y además crea y sube el tag):

   ```bash
   gh release create mobile-v0.1.0 build/dist/0.1.0/*.apk build/dist/0.1.0/SHA256SUMS.txt \
     --repo zimmercanoa/judy-simulator-orca --title "JuDy Simulator 0.1.0 (Android)" \
     --notes "Verifica el SHA-256 en SHA256SUMS.txt o en https://judysimulator.wuaze.com/descargar.php"
   ```

4. Haz commit de `descargas/app.json` y despliega el sitio: `descargar.php`
   mostrará versión, tamaño y SHA-256, y la app avisará de la actualización.

## 4. Checklist de seguridad de la compilación

| Medida | Dónde |
| --- | --- |
| Solo HTTPS, sin tráfico en claro | `res/xml/network_security_config.xml`, `usesCleartextTraffic=false` |
| Sin copia de seguridad del almacenamiento | `allowBackup=false`, `data_extraction_rules.xml` |
| Ofuscación Dart + R8 (minify y shrinkResources) | `--obfuscate`, `build.gradle.kts` |
| Token cifrado (Keystore) y borrado al salir / 401 / eliminar cuenta | `token_store.dart`, `session.dart` |
| Permisos mínimos: solo `INTERNET` | `AndroidManifest.xml` |
| FLAG_SECURE en login y registro | `MainActivity.kt`, `pantalla_segura.dart` |
| Sin secretos en la app (Gemini solo en `config.php`) | — |
| Timeouts (20 s) y validación de entradas | `config.dart`, `validadores.dart`, API |
| Eliminar cuenta en app y web | `home_screen.dart`, `api/eliminar_cuenta.php`, `eliminar_cuenta.php` |

Más detalle y mejoras opcionales (certificate pinning) en [SEGURIDAD.md](SEGURIDAD.md).

## 5. Recordatorio: la API y el hosting

Mientras la API esté en InfinityFree gratuito, la app recibe el desafío
anti-bots y solo funciona en **modo demo** (ver `mobile/README.md`). Para usar
datos reales, publica `api/` en otro hosting y compila con
`-ApiBaseUrl https://nuevo-host/api`.

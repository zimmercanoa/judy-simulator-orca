# Distribución directa de la APK (sin Google Play)

La app se distribuye como APK descargable desde **`descargar.php`** del sitio
(`https://CUENTA.alwaysdata.net/descargar.php`, con respaldo en
`https://judysimulator.wuaze.com/descargar.php`). Los archivos viven en
**GitHub Releases** de `zimmercanoa/judy-simulator-orca` (tag `mobile-vX.Y.Z`),
no en el repositorio ni en el hosting.

```text
tag mobile-v0.1.0 ──> build-apk.yml (GitHub Actions) ──> Release: APK + SHA256SUMS.txt + descargas-app.json
                                                                    │
descargar.php ──lee──> descargas/app.json  <──copiar──────────────┘
api/version.php ──lee──> descargas/app.json ──> aviso "nueva versión" en la app
```

## 1. Clave de firma (una sola vez) — ¡CRÍTICO!

Android solo instala una actualización encima de la versión anterior si ambas
están firmadas con **la misma clave**. Si se pierde, los usuarios tendrán que
desinstalar la app para instalar la siguiente versión.

Necesitas `keytool`, que viene con cualquier JDK 17 (p. ej. Eclipse Temurin) o
con Android Studio (`C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe`).

```bash
keytool -genkeypair -v -keystore judy-release.jks -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 -alias judy-release \
  -dname "CN=JuDy Simulator, OU=Desarrollo, O=JuDy Simulator, L=Guanajuato, ST=Guanajuato, C=MX"
```

(o con el asistente: `.\store\scripts\generar_keystore.ps1 -Destino "$env:USERPROFILE\judy-claves\judy-release.jks"`,
que además crea `android/key.properties` para compilar en local).

- Guarda el `.jks` **fuera del repositorio** (`.gitignore` bloquea `*.jks`, `*.keystore`, `key.properties`).
- **Respaldo obligatorio:** el `.jks`, el alias y la contraseña en un gestor de
  contraseñas + una copia cifrada/USB. Nunca por correo ni en el repo.

### Convertir el keystore a base64 (para GitHub Secrets)

```powershell
# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$env:USERPROFILE\judy-claves\judy-release.jks")) | Set-Clipboard
```

```bash
base64 -w0 judy-release.jks > judy-release.b64     # Linux
base64 -i judy-release.jks | pbcopy                # macOS
```

Borra el archivo `.b64` después de copiarlo.

## 2. Secrets y variables en GitHub (una sola vez)

https://github.com/zimmercanoa/judy-simulator-orca/settings/secrets/actions

| Tipo | Nombre | Valor |
|---|---|---|
| Secret | `ANDROID_KEYSTORE_BASE64` | contenido base64 del `.jks` |
| Secret | `ANDROID_KEYSTORE_PASSWORD` | contraseña del keystore |
| Secret | `ANDROID_KEY_ALIAS` | `judy-release` |
| Secret | `ANDROID_KEY_PASSWORD` | contraseña de la clave (la misma, si usaste el comando de arriba y no cambiaste nada) |
| Variable | `SITE_URL` | `https://CUENTA.alwaysdata.net` |

Sin `ANDROID_KEYSTORE_BASE64` el workflow se niega a publicar (no firma con la
clave debug). Sin `SITE_URL` la APK arranca en modo demo.

## 3. Publicar una versión (GitHub Actions — recomendado, sin SDK local)

1. Sube la versión en el código (la prueba `test/version_test.dart` falla si no coinciden):
   - `mobile/pubspec.yaml` → `version: 0.2.0+2` (el número tras `+` siempre debe aumentar).
   - `mobile/lib/config.dart` → `appVersion` y `appVersionCode`.
   - `descargas/app.json` → `version` y `version_code` (los demás campos los rellena el paso 4).
2. Haz merge a `master`.
3. Crea y sube el tag desde `master`:

   ```bash
   git tag -a mobile-v0.2.0 -m "App móvil 0.2.0"
   git push zimmercanoa mobile-v0.2.0
   ```

   `.github/workflows/build-apk.yml` comprueba que el tag coincide con
   `pubspec.yaml`, ejecuta `flutter analyze` y `flutter test`, compila
   `flutter build apk --release --split-per-abi --obfuscate --split-debug-info=…`
   con `SITE_URL`, y publica en el Release:
   `judy-simulator-<versión>-{arm64-v8a,armeabi-v7a,x86_64}.apk`,
   `SHA256SUMS.txt` y `descargas-app.json`. Los símbolos de depuración quedan
   como artefacto privado del workflow (90 días; descárgalos y guárdalos si
   necesitas leer errores de esa versión).
4. Descarga `descargas-app.json` del Release, cópialo sobre `descargas/app.json`,
   añade las notas de la versión en `"notas"`, haz commit y push a `master`:
   el despliegue actualiza `descargar.php` y la app avisará de la actualización.

## 3b. Alternativa: compilar en local

Requiere Flutter 3.47.4, Android Studio (SDK + JDK) y `android/key.properties`
(ver `android/key.properties.example`):

```powershell
cd mobile
.\store\scripts\publicar_release.ps1 -Notas "Qué cambió" -SiteUrl "https://CUENTA.alwaysdata.net"
```

Genera las APK en `build/dist/<versión>/`, actualiza `descargas/app.json` e
imprime el comando `gh release create …` (con `-Publicar` lo ejecuta; requiere `gh auth login`).

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
| Keystore solo en GitHub Secrets / fuera del repo; se borra del runner al terminar | `build-apk.yml` |
| Timeouts (20 s) y validación de entradas | `config.dart`, `validadores.dart`, API |
| Eliminar cuenta en app y web | `home_screen.dart`, `api/eliminar_cuenta.php`, `eliminar_cuenta.php` |

Más detalle y mejoras opcionales (certificate pinning) en [SEGURIDAD.md](SEGURIDAD.md).

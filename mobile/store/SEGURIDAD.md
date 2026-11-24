# Seguridad de la app móvil

## Implementado

- **Transporte:** solo HTTPS. `network_security_config.xml` prohíbe el tráfico en
  claro y confía solo en las CA del sistema (no en CA instaladas por el usuario).
  La variante *debug* permite HTTP únicamente hacia `10.0.2.2`/`localhost` para
  probar con XAMPP.
- **Sesión:** token Bearer aleatorio de 256 bits; el servidor guarda solo su
  SHA-256 con caducidad de 30 días. En el teléfono se guarda con
  `flutter_secure_storage` (cifrado con una clave del Android Keystore). Se borra
  al cerrar sesión, al recibir `401` y al eliminar la cuenta.
- **Sin copias de seguridad:** `allowBackup=false` y `data_extraction_rules.xml`
  excluyen todo; además, una copia del token cifrado no se podría descifrar en otro equipo.
- **Código:** `--obfuscate --split-debug-info` (Dart) + R8 `minifyEnabled` y
  `shrinkResources` (Android). Los símbolos se guardan fuera del repo.
- **Permisos:** solo `android.permission.INTERNET`.
- **FLAG_SECURE:** activo en login y registro (bloquea capturas y la miniatura de
  «recientes»). Para extenderlo a otra pantalla: `with PantallaSeguraMixin<MiPantalla>`.
- **Secretos:** la app no contiene claves. La clave de Gemini, SMTP y MySQL
  viven solo en `config.php` del servidor.
- **Entradas:** validación en cliente (`validadores.dart`) y en servidor
  (longitudes, formatos, `in_array` estricto, consultas preparadas), timeouts de
  20 s y rate limiting por IP/usuario en la API.
- **Firma:** keystore fuera del repo; `key.properties`, `*.jks`, `*.keystore` en `.gitignore`.

## Opcional: certificate pinning

Fija la clave pública del certificado del servidor de la API para impedir
ataques con CA comprometidas o instaladas por el usuario.

- **Opción Android nativa** (no requiere código Dart): añadir en
  `network_security_config.xml`:

  ```xml
  <domain-config>
      <domain includeSubdomains="true">api.tu-dominio.com</domain>
      <pin-set expiration="2027-12-31">
          <pin digest="SHA-256">BASE64_DEL_SPKI_ACTUAL=</pin>
          <pin digest="SHA-256">BASE64_DEL_SPKI_DE_RESPALDO=</pin>
      </pin-set>
  </domain-config>
  ```

  Obtener el pin: `openssl s_client -connect api.tu-dominio.com:443 | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64`.
- **Requisitos del servidor:** dominio propio con certificado estable (o pin de la
  CA intermedia), un pin de respaldo y un plan de rotación: si el certificado
  cambia sin que la app tenga el nuevo pin, **la app dejará de conectar** hasta
  que se instale una nueva versión. Con Let's Encrypt (renovación cada 90 días)
  conviene fijar la clave reutilizando la misma clave privada o fijar la CA.
- No tiene sentido con InfinityFree gratuito (la API no es accesible desde la app).

## Opcional: Play Integrity API

Solo aplica si algún día la app se publica en Google Play: requiere Play Console,
vincular un proyecto de Google Cloud y que el servidor verifique cada *token de
integridad* contra la API de Google (con credenciales de cuenta de servicio en el
servidor) antes de aceptar el login. Para distribución directa de APK no está disponible.

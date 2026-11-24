# Despliegue — JuDy Simulator

El mismo código (`master`) se publica en dos hostings mediante GitHub Actions.
`config.php` nunca se sube: se crea a mano en cada servidor a partir de `config.sample.php`.

| | **alwaysdata** (principal) | **InfinityFree** (respaldo) |
|---|---|---|
| URL | `https://CUENTA.alwaysdata.net` | `https://judysimulator.wuaze.com` |
| Web en navegador | ✅ | ✅ |
| API JSON para la app móvil | ✅ | ❌ desafío anti-bots `aes.js` / cookie `__test` |
| Restricción de nombres | — | 403 en cualquier URL con «chat» |
| Base de datos | `CUENTA_judyb` en `mysql-CUENTA.alwaysdata.net` | `if0_43331816_JuDyb` en `sql310.infinityfree.com` |
| Carpeta | `www/` | `htdocs/` |
| Workflow | `.github/workflows/deploy-alwaysdata.yml` | `.github/workflows/deploy.yml` |
| Secrets | `ALWAYSDATA_FTP_SERVER/USER/PASSWORD` | `FTP_SERVER/USERNAME/PASSWORD` |
| Guía | [DESPLIEGUE_ALWAYSDATA.md](DESPLIEGUE_ALWAYSDATA.md) | [DESPLIEGUE_INFINITYFREE.md](DESPLIEGUE_INFINITYFREE.md) |

Ambos workflows corren al hacer push a `master` y excluyen `config.php`,
`mobile/`, `sql/`, `*.md`, `*.sql`, `.github/`, `.agents/`, `.gemini/`, `tools/`, `gems/`.

## Base de datos en cualquiera de los dos

Importar en phpMyAdmin, en orden y sin cambios:

1. `JuDyb.sql`
2. `sql/migracion_api_tokens.sql` (tablas de la API móvil)

## App móvil

- APK: tag `mobile-vX.Y.Z` → `.github/workflows/build-apk.yml` compila y publica en GitHub Releases
  (ver `mobile/store/DISTRIBUCION_APK.md`).
- La app usa la URL de alwaysdata (`SITE_URL`); InfinityFree solo sirve como portal web de respaldo.

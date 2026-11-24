# Servidores MCP compartidos — cuándo usar cada uno

Configurados en `.mcp.json` (Claude Code), `.gemini/settings.json` (Gemini CLI),
`opencode.json` (opencode) y `tools/mcp/antigravity_mcp_config.json` (Antigravity).
Guía completa y puesta en marcha: `HERRAMIENTAS.md` → «Servidores MCP».

| MCP | Úsalo para | No lo uses para |
|---|---|---|
| `playwright` | Verificar en producción (https://judysimulator.wuaze.com tiene el desafío anti-bots `aes.js` que `curl`/`judy_monitor.py` no pasan; https://dilanisraelrodriguezcano.alwaysdata.net), revisar formularios, títulos, errores PHP visibles y consola. | Iniciar sesión con cuentas reales, escribir credenciales en formularios o hacer cambios de datos en producción sin que el dueño lo pida. |
| `github` | Leer PRs, checks de Actions, issues, ramas y commits de `zimmercanoa/judy-simulator-orca`. Es **solo lectura** por defecto. | Escribir: para comentar, crear PRs o hacer merge usa `gh` (y solo si la tarea lo pide). |
| `context7` | Documentación actual de Flutter/Dart, paquetes pub, PHP y GitHub Actions antes de usar una API que no conoces con certeza. | Sustituir las reglas del proyecto: `GEMINI.md` y `.agents/rules/` mandan. |

Reglas:
1. En InfinityFree, verifica endpoints con Playwright en vez de `curl`; en alwaysdata, `judy_monitor.py` sigue valiendo.
2. Nunca escribas contraseñas, tokens ni datos personales en páginas, capturas, snapshots o logs. Si una captura los muestra, descártala.
3. El token de GitHub vive solo en la variable de entorno `GITHUB_PERSONAL_ACCESS_TOKEN`; jamás en archivos, chats, PRs ni salidas de comandos.
4. Versiones fijas (sin `@latest`). Para actualizar, cambia la versión en los cuatro archivos y ejecuta `python tools/mcp_check.py --smoke`.

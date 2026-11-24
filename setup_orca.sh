#!/bin/sh
set -e
cd "$(dirname "$0")"

echo "== JuDy Simulator - preparacion de entorno Orca =="

if command -v python3 >/dev/null 2>&1; then
    PY=python3
elif command -v python >/dev/null 2>&1; then
    PY=python
else
    echo "Python 3 no encontrado. Instala Python 3.9+." >&2
    exit 1
fi

"$PY" tools/judy_gem_sync.py
"$PY" tools/judy_audit.py --strict

# Servidores MCP (.mcp.json, .gemini/settings.json, opencode.json): no bloquean el setup.
for f in .mcp.json opencode.json .gemini/settings.json tools/mcp/antigravity_mcp_config.json; do
    [ -f "$f" ] || echo "AVISO: falta $f (configuracion MCP compartida)" >&2
done
if ! command -v npx >/dev/null 2>&1; then
    echo "AVISO: npx no encontrado; instala Node.js 18+ para Playwright y Context7." >&2
elif [ -z "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]; then
    echo "AVISO: GITHUB_PERSONAL_ACCESS_TOKEN no definida; ejecuta: export GITHUB_PERSONAL_ACCESS_TOKEN=\"\$(gh auth token)\" (ver HERRAMIENTAS.md)" >&2
else
    "$PY" tools/mcp_check.py || echo "AVISO: algun servidor MCP no respondio (ver HERRAMIENTAS.md)" >&2
fi

echo ""
echo "Entorno listo. Abre esta carpeta en Orca y revisa LEEME_ENTORNO.md."

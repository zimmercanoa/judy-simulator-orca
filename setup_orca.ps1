$ErrorActionPreference = 'Stop'
Write-Host "== JuDy Simulator - preparacion de entorno Orca =="

$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    $python = Get-Command py -ErrorAction SilentlyContinue
}
if (-not $python) {
    throw "Python 3 no encontrado. Instala Python 3.9+ y vuelve a ejecutar este script."
}

Push-Location $PSScriptRoot
try {
    & $python.Source tools/judy_gem_sync.py
    if ($LASTEXITCODE -ne 0) { throw " judy_gem_sync.py devolvio $LASTEXITCODE" }

    & $python.Source tools/judy_audit.py --strict
    if ($LASTEXITCODE -ne 0) { throw " judy_audit.py encontro hallazgos criticos" }

    # Servidores MCP (.mcp.json, .gemini/settings.json, opencode.json): no bloquean el setup.
    foreach ($f in '.mcp.json', 'opencode.json', '.gemini/settings.json', 'tools/mcp/antigravity_mcp_config.json') {
        if (-not (Test-Path $f)) { Write-Warning "Falta $f (configuracion MCP compartida)" }
    }
    if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
        Write-Warning "npx no encontrado: instala Node.js 18+ para los servidores MCP Playwright y Context7."
    } elseif (-not $env:GITHUB_PERSONAL_ACCESS_TOKEN) {
        Write-Warning "GITHUB_PERSONAL_ACCESS_TOKEN no definida: el MCP de GitHub no conectara. Ejecuta: setx GITHUB_PERSONAL_ACCESS_TOKEN (gh auth token)  (ver HERRAMIENTAS.md)"
    } else {
        & $python.Source tools/mcp_check.py
        if ($LASTEXITCODE -ne 0) { Write-Warning "Algun servidor MCP no respondio (ver HERRAMIENTAS.md > Servidores MCP)" }
    }

    Write-Host "`nEntorno listo. Abre esta carpeta en Orca y revisa LEEME_ENTORNO.md."
} finally {
    Pop-Location
}

# Ecosistema de gems y herramientas (JuDy Simulator)

Una sola fuente de verdad para que **Gemini CLI, Antigravity, Gemini (app) y
cualquier otro agente** trabajen con las mismas reglas y las mismas comprobaciones.

## Mapa rápido

| Plataforma | Dónde están las "gems" | Cómo se invocan |
|---|---|---|
| Antigravity (IDE/CLI) | `.agents/skills/<nombre>/SKILL.md` | Coincidencia por `description` |
| Antigravity (agente dedicado) | `.agents/agents/*.md` | Selección de agente en la UI |
| Antigravity (reglas) | `GEMINI.md` + `.agents/rules/*.md` | Siempre activas |
| Gemini CLI | `.gemini/commands/judy/*.toml` | `/judy:audit`, `/judy:monitor`, `/judy:seguridad`, `/judy:sql`, `/judy:sync` |
| Gemini CLI (skills) | `.agents/skills/` (alias soportado) | Coincidencia por descripción |
| Gemini (app, "Gems") | `gems/*.md` | Pegar el bloque "Instrucciones del sistema" al crear el Gem |
| Cualquier agente | `tools/*.py` | `python tools/<script>.py` |
| Claude Code (MCP) | `.mcp.json` | Herramientas `mcp__playwright__*`, `mcp__github__*`, `mcp__context7__*` |
| Gemini CLI (MCP) | `.gemini/settings.json` → `mcpServers` | `/mcp` para verlos |
| opencode (MCP) | `opencode.json` → `mcp` | Automático al abrir el proyecto |
| Antigravity (MCP) | `tools/mcp/antigravity_mcp_config.json` (copiar, ver abajo) | Panel MCP de Antigravity |

## Skills incluidas

- **predeploy-audit** → `/judy:audit`: auditoría antes de commit/push/FTP.
- **prod-monitor** → `/judy:monitor`: auditoría HTTP de los 6 endpoints públicos.
- **seguridad-php** → `/judy:seguridad`: CSRF, SQLi, XSS, secretos y correo.
- **infinity-sql** → `/judy:sql`: compatibilidad del dump con InfinityFree.
- **gem-sync** → `/judy:sync`: mantiene sincronizados skills, comandos y Gems.

Agentes dedicados: `judy-release-guardian` (aprobar/bloquear despliegues) y
`judy-security-auditor` (revisión de PRs de seguridad).

## Puesta en marcha (30 segundos)

```bash
# 1. Comprobar que las gems están sincronizadas
python tools/judy_gem_sync.py

# 2. Auditoría obligatoria antes de cualquier cambio
python tools/judy_audit.py --strict

# 3. Tras el despliegue
python tools/judy_monitor.py --url https://judysimulator.wuaze.com
```

Si un agente no ve un comando:

```bash
python tools/judy_gem_sync.py --write
python tools/judy_audit.py --strict
```

## Servidores MCP

Tres servidores compartidos, con versiones fijas (≥ 2 semanas de antigüedad):

| Servidor | Paquete / URL | Para qué |
|---|---|---|
| `playwright` | `npx -y @playwright/mcp@0.0.85 --headless --isolated` | Navegador real: pasa el desafío `aes.js` de InfinityFree que `curl` no supera. Perfil en memoria (`--isolated`): no guarda cookies. |
| `github` | Servidor remoto oficial `https://api.githubcopilot.com/mcp/` | PRs, Actions, issues y código. Cabeceras `X-MCP-Toolsets: repos,pull_requests,actions,issues` y `X-MCP-Readonly: true`. |
| `context7` | `npx -y @upstash/context7-mcp@4.6.0` | Documentación actual de Flutter, Dart, PHP, etc. |

Reglas de uso para agentes: `.agents/rules/mcp.md`.

### Paso único del dueño: variable de entorno del token

El token **nunca** se escribe en archivos del repositorio; todos los clientes lo leen
de `GITHUB_PERSONAL_ACCESS_TOKEN`. `gh` ya tiene sesión en este equipo:

```powershell
# Windows (persistente para tu usuario; reinicia Orca/terminales después)
setx GITHUB_PERSONAL_ACCESS_TOKEN (gh auth token) > $null

# Solo para la terminal actual
$env:GITHUB_PERSONAL_ACCESS_TOKEN = gh auth token
```

```bash
# Linux / macOS (añádelo a ~/.bashrc o ~/.zshrc)
export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token)"
```

No ejecutes `echo $env:GITHUB_PERSONAL_ACCESS_TOKEN` ni pegues su valor en chats. Si
prefieres un token más limitado que el de `gh`, crea un *fine-grained PAT* de solo
lectura para `zimmercanoa/judy-simulator-orca` (Contents, Pull requests, Issues,
Actions: Read) y ponlo en la misma variable. Si el token se filtra: `gh auth refresh`
(o revoca el PAT) y vuelve a ejecutar `setx`.

### Por cliente

- **Claude Code**: `.mcp.json` (alcance de proyecto). La primera vez, abre `claude` en la
  carpeta y aprueba los tres servidores (o `/mcp`). Comprobar: `claude mcp list`.
  Usa `cmd /c npx` porque en Windows `npx` es un `.cmd`; en Linux/macOS cambia
  `"command": "cmd", "args": ["/c", "npx", ...]` por `"command": "npx", "args": [...]`.
- **Gemini CLI**: `.gemini/settings.json` (solo `mcpServers`, sin hooks ni rutas
  locales; los hooks de Orca viven en `~/.gemini/settings.json`). Comprobar: `gemini mcp list`.
- **opencode**: `opencode.json` en la raíz (sección `mcp`). Comprobar: `opencode mcp list`.
  Igual que Claude Code, quita `cmd /c` fuera de Windows.
- **Antigravity**: lee los MCP de su archivo global `~/.gemini/antigravity/mcp_config.json`,
  no del proyecto. Cópialo una vez (si ya tienes ese archivo, fusiona la sección `mcpServers`):

  ```powershell
  Copy-Item tools\mcp\antigravity_mcp_config.json "$env:USERPROFILE\.gemini\antigravity\mcp_config.json"
  ```

  Ahí GitHub se conecta mediante `mcp-remote@0.16.5`, que expande
  `${GITHUB_PERSONAL_ACCESS_TOKEN}` desde el entorno; el archivo sigue sin contener el token.

### Verificación

```bash
python tools/mcp_check.py          # handshake MCP + lista de herramientas de cada servidor
python tools/mcp_check.py --smoke  # Playwright abre judysimulator.wuaze.com y lee el título;
                                   # GitHub lista los PRs; Context7 resuelve "flutter"
```

Para actualizar una versión, cámbiala en `.mcp.json`, `.gemini/settings.json`,
`opencode.json` y `tools/mcp/antigravity_mcp_config.json`, y repite `--smoke`.
`judy_audit.py` falla si alguno contiene un token literal (MCP-002) y avisa de `@latest` (MCP-003).

## Reglas de oro para agentes

1. `GEMINI.md` manda: tablas en minúsculas, `config.php` centralizado, sin BOM, sin secretos.
2. Ningún agente modifica credenciales; si las ve, usa `****` y pide rotarlas.
3. Todo cambio termina con `judy_audit.py`. Todo despliegue termina con `judy_monitor.py`.
4. Una excepción de seguridad debe llevar `// csrf-exception: <motivo>` en el código.
5. Las Gems de la app Gemini se generan desde las skills; edita la skill, nunca el derivado.

## Notas de repositorio

- `.gitignore` versiona `.gemini/commands/` y `.gemini/settings.json` (solo `mcpServers`), e ignora el resto de `.gemini/`.
- `.mcp.json` y `opencode.json` están excluidos del FTP.
- `.agents/` está versionado (para compartirlo) pero **excluido del FTP**.
- `tools/`, `gems/`, `*.sql` y `*.md` también quedan fuera del despliegue.

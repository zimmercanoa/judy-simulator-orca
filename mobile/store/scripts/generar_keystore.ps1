# ============================================================
#  generar_keystore.ps1 — Crea la clave de firma de release y el
#  archivo android/key.properties.
#
#  Uso (PowerShell, desde la carpeta mobile/):
#    .\store\scripts\generar_keystore.ps1 -Destino "$env:USERPROFILE\judy-claves\judy-release.jks"
#
#  - El .jks se crea FUERA del repositorio (no lo subas nunca).
#  - Distribución directa de APK: esta es la clave DEFINITIVA. Si se
#    pierde, ninguna versión nueva se podrá instalar encima de la anterior.
#    Respáldala (gestor de contraseñas + copia cifrada).
#  - Si algún día se usa Google Play, con Play App Signing esta clave
#    pasaría a ser solo la clave de subida.
#  - Requiere keytool (incluido en el JDK de Android Studio:
#    "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe").
# ============================================================
param(
    [Parameter(Mandatory = $true)][string]$Destino,
    [string]$Alias = "judy-release"
)

$ErrorActionPreference = "Stop"

$keytool = (Get-Command keytool -ErrorAction SilentlyContinue).Source
if (-not $keytool) {
    $jbr = "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
    if (Test-Path $jbr) { $keytool = $jbr } else { throw "No se encontró keytool. Instala Android Studio o un JDK 17." }
}

$repo = (git rev-parse --show-toplevel 2>$null)
if ($repo -and ([IO.Path]::GetFullPath($Destino)).StartsWith(([IO.Path]::GetFullPath($repo)), [StringComparison]::OrdinalIgnoreCase)) {
    throw "El keystore no debe guardarse dentro del repositorio. Elige otra ruta."
}
if (Test-Path $Destino) { throw "Ya existe $Destino. No se sobrescribe." }

New-Item -ItemType Directory -Force (Split-Path $Destino) | Out-Null
$pass = Read-Host "Contraseña del keystore (mínimo 6 caracteres)" -AsSecureString
$plano = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass))

& $keytool -genkeypair -v -keystore $Destino -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 `
    -alias $Alias -storepass $plano -keypass $plano `
    -dname "CN=JuDy Simulator, OU=Desarrollo, O=JuDy Simulator, L=Guanajuato, ST=Guanajuato, C=MX"

$props = Join-Path $PSScriptRoot "..\..\android\key.properties"
@"
storePassword=$plano
keyPassword=$plano
keyAlias=$Alias
storeFile=$($Destino -replace '\\','/')
"@ | Out-File -Encoding ascii $props

Write-Host "Keystore creado en $Destino"
Write-Host "android/key.properties generado (está en .gitignore)."
Write-Host "Haz una copia de seguridad del .jks y la contraseña en un gestor de contraseñas."

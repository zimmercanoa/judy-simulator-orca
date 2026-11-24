# ============================================================
#  publicar_release.ps1 — Compila las APK firmadas, calcula tamaño y
#  SHA-256, actualiza descargas/app.json y publica (o muestra el
#  comando para publicar) el GitHub Release mobile-vX.Y.Z.
#
#  Uso (PowerShell, desde la carpeta mobile/):
#    .\store\scripts\publicar_release.ps1 [-SiteUrl https://CUENTA.alwaysdata.net] [-Notas "..."] [-Publicar]
#
#  Requisitos: Flutter, Android SDK, android/key.properties con el
#  keystore de release (ver DISTRIBUCION_APK.md) y, para -Publicar,
#  GitHub CLI con sesión (gh auth login).
# ============================================================
param(
    [string]$SiteUrl = "",
    [string]$Notas = "",
    [string]$Repo = "zimmercanoa/judy-simulator-orca",
    [switch]$Publicar
)
$ErrorActionPreference = "Stop"

$mobile = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$raiz = Resolve-Path (Join-Path $mobile "..")
Set-Location $mobile

if (-not (Test-Path "android\key.properties")) {
    throw "Falta android\key.properties: sin el keystore de release la APK no se puede actualizar después. Ver store\DISTRIBUCION_APK.md."
}

# Versión desde pubspec.yaml (X.Y.Z+N)
$linea = Select-String -Path pubspec.yaml -Pattern '^version:\s*(\d+\.\d+\.\d+)\+(\d+)' | Select-Object -First 1
if (-not $linea) { throw "No se encontró 'version: X.Y.Z+N' en pubspec.yaml" }
$version = $linea.Matches[0].Groups[1].Value
$code = [int]$linea.Matches[0].Groups[2].Value
$tag = "mobile-v$version"
Write-Host "Versión $version (code $code) -> tag $tag"

# Símbolos de depuración FUERA del repo (necesarios para leer stack traces ofuscados)
$simbolos = Join-Path $env:USERPROFILE "judy-simbolos\$version"
New-Item -ItemType Directory -Force $simbolos | Out-Null

$defines = @()
if ($SiteUrl -ne "") { $defines += "--dart-define=SITE_URL=$SiteUrl" } else { Write-Warning "Sin -SiteUrl la APK arrancará en modo demo." }

flutter pub get
flutter test
flutter build apk --release --split-per-abi --obfuscate --split-debug-info="$simbolos" @defines
if ($LASTEXITCODE -ne 0) { throw "Falló flutter build apk" }

$salida = "build\app\outputs\flutter-apk"
$dist = Join-Path $mobile "build\dist\$version"
New-Item -ItemType Directory -Force $dist | Out-Null

$apks = @()
foreach ($abi in @("arm64-v8a", "armeabi-v7a", "x86_64")) {
    $origen = Join-Path $salida "app-$abi-release.apk"
    if (-not (Test-Path $origen)) { continue }
    $nombre = "judy-simulator-$version-$abi.apk"
    $destino = Join-Path $dist $nombre
    Copy-Item $origen $destino -Force
    $hash = (Get-FileHash $destino -Algorithm SHA256).Hash.ToLower()
    $tamano = (Get-Item $destino).Length
    "$hash  $nombre" | Out-File -Append -Encoding ascii (Join-Path $dist "SHA256SUMS.txt")
    $apks += [ordered]@{
        abi = $abi
        archivo = $nombre
        tamano_bytes = $tamano
        sha256 = $hash
        url = "https://github.com/$Repo/releases/download/$tag/$nombre"
    }
    Write-Host ("{0,-12} {1,8:N1} MB  {2}" -f $abi, ($tamano / 1MB), $hash)
}
if ($apks.Count -eq 0) { throw "No se generaron APK en $salida" }

# Metadatos para descargar.php y api/version.php
$json = [ordered]@{
    version = $version
    version_code = $code
    publicada = $true
    fecha = (Get-Date -Format "yyyy-MM-dd")
    android_minimo = "Android 7.0 (API 24)"
    release_url = "https://github.com/$Repo/releases/tag/$tag"
    notas = $Notas
    apks = $apks
}
$json | ConvertTo-Json -Depth 5 | Out-File -Encoding utf8 (Join-Path $raiz "descargas\app.json")
# Quitar BOM (PowerShell 5.1 lo añade con utf8)
$ruta = Join-Path $raiz "descargas\app.json"
[IO.File]::WriteAllText($ruta, [IO.File]::ReadAllText($ruta).TrimStart([char]0xFEFF))
Write-Host "descargas/app.json actualizado."

$archivos = (Get-ChildItem $dist -File | ForEach-Object { '"' + $_.FullName + '"' }) -join " "
$cmd = "gh release create $tag $archivos --repo $Repo --title `"JuDy Simulator $version (Android)`" --notes `"$Notas`n`nVerifica el SHA-256 en SHA256SUMS.txt o en https://judysimulator.wuaze.com/descargar.php`""

if ($Publicar) {
    gh auth status | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'GitHub CLI sin sesión: run "gh auth login"' }
    # Remote cuyo URL apunta a $Repo (en este proyecto suele ser "zimmercanoa", no "origin")
    $remote = git -C $raiz remote -v | Select-String ([regex]::Escape($Repo)) | Select-Object -First 1 | ForEach-Object { ($_.Line -split "\s+")[0] }
    if (-not $remote) { throw "Ningún remote apunta a $Repo" }
    if (-not (git -C $raiz tag -l $tag)) { git -C $raiz tag -a $tag -m "App móvil $version" }
    git -C $raiz push $remote $tag
    Invoke-Expression $cmd
} else {
    Write-Host "`nPara publicar el release ejecuta:`n$cmd"
}
Write-Host "`nDespués: haz commit de descargas/app.json y despliega el sitio para que descargar.php muestre la versión."
Write-Host "Símbolos de depuración guardados en $simbolos (respáldalos; NO los subas al repo)."

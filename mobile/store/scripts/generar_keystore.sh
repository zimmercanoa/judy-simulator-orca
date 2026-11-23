#!/usr/bin/env bash
# ============================================================
#  generar_keystore.sh — Crea la clave de firma de release (definitiva: respáldala)
#  y android/key.properties (macOS/Linux/Git Bash).
#
#  Uso (desde mobile/):  ./store/scripts/generar_keystore.sh ~/judy-claves/judy-release.jks
#  El .jks debe quedar FUERA del repositorio. Requiere keytool (JDK 17).
# ============================================================
set -euo pipefail

destino="${1:?Indica la ruta del .jks, p. ej. ~/judy-claves/judy-release.jks}"
alias_clave="${2:-judy-release}"

command -v keytool >/dev/null || { echo "No se encontró keytool (instala un JDK 17 o Android Studio)." >&2; exit 1; }
repo="$(git rev-parse --show-toplevel 2>/dev/null || true)"
abs="$(cd "$(dirname "$destino")" 2>/dev/null && pwd || mkdir -p "$(dirname "$destino")" && cd "$(dirname "$destino")" && pwd)/$(basename "$destino")"
if [[ -n "$repo" && "$abs" == "$repo"* ]]; then
  echo "El keystore no debe guardarse dentro del repositorio." >&2; exit 1
fi
[[ -e "$abs" ]] && { echo "Ya existe $abs; no se sobrescribe." >&2; exit 1; }

read -r -s -p "Contraseña del keystore (mínimo 6 caracteres): " pass; echo

keytool -genkeypair -v -keystore "$abs" -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 \
  -alias "$alias_clave" -storepass "$pass" -keypass "$pass" \
  -dname "CN=JuDy Simulator, OU=Desarrollo, O=JuDy Simulator, L=Guanajuato, ST=Guanajuato, C=MX"

props="$(dirname "$0")/../../android/key.properties"
umask 077
cat > "$props" <<EOF
storePassword=$pass
keyPassword=$pass
keyAlias=$alias_clave
storeFile=$abs
EOF

echo "Keystore creado en $abs"
echo "android/key.properties generado (está en .gitignore). Respalda el .jks y la contraseña."

#!/usr/bin/env bash
# Jitterx Script - instalador. Sin licencia valida NO se instala ni descarga nada.
#   wget -qO install.sh https://raw.githubusercontent.com/jittervpn/jitterx-script/main/install.sh && bash install.sh
# Modo automatico: JITTERX_KEY=JX-XXXX-XXXX-XXXX-XXXX bash install.sh --auto
set -u
JITTERX_SERVER="${JITTERX_SERVER:-https://reg.jitterxcloud.dev:8444}"   # <-- URL de tu servidor de licencias

R='\e[1;31m'; G='\e[1;32m'; Y='\e[1;33m'; W='\e[1;37m'; N='\e[0m'
die() { echo -e "${R}✘${N} $*" >&2; exit 1; }
AUTO=0; [ "${1:-}" = "--auto" ] && AUTO=1

[ "$(id -u)" -eq 0 ] || die "Ejecuta como root"
command -v curl >/dev/null || { command -v apt >/dev/null && apt update -y >/dev/null 2>&1 && apt install -y curl >/dev/null 2>&1; }
command -v curl >/dev/null || die "Se requiere curl"

# ---- 1) Licencia: lo PRIMERO. Si falla, se sale antes de tocar el sistema ----
KEY="${JITTERX_KEY:-}"
for i in 1 2 3; do
  if [ -z "$KEY" ]; then
    [ $AUTO -eq 1 ] && die "Falta JITTERX_KEY"
    echo -e "${W}Jitterx Script requiere una licencia${N}"
    read -rp " Key: " KEY
  fi
  KEY=$(echo "$KEY" | tr 'a-z' 'A-Z' | tr -d ' ')
  RES=$(curl -fsS --max-time 10 -H "X-Jitterx-Key: $KEY" "$JITTERX_SERVER/api/validate" 2>/dev/null)
  if echo "$RES" | grep -q '"ok": *true'; then OK=1; break; fi
  ERR=$(echo "$RES" | sed -n 's/.*"error": *"\([^"]*\)".*/\1/p')
  echo -e "${R}✘${N} Licencia rechazada: ${ERR:-sin respuesta del servidor}"
  KEY=""; OK=0
done
[ "${OK:-0}" -eq 1 ] || die "Licencia invalida. No se instalo nada."

# ---- 2) Descarga del paquete (solo con licencia valida) ----
TMP=$(mktemp /tmp/jitterx.XXXXXX) || die "No se pudo crear archivo temporal"
trap 'rm -f "$TMP"' EXIT
curl -fsS --max-time 60 -H "X-Jitterx-Key: $KEY" "$JITTERX_SERVER/api/payload?file=jitterx.sh" -o "$TMP" \
  && [ -s "$TMP" ] && head -c 2 "$TMP" | grep -q '#!' || die "No se pudo descargar el paquete. No se instalo nada."

# ---- 3) Ejecutar instalador completo ----
export JITTERX_KEY="$KEY" JITTERX_SERVER
if [ $AUTO -eq 1 ]; then bash "$TMP" --auto; else bash "$TMP"; fi

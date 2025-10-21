#!/usr/bin/env bash
set -eo pipefail

get_wifi_device() {
  /usr/sbin/networksetup -listallhardwareports 2>/dev/null \
    | awk 'BEGIN{hit=0} /Hardware Port: Wi-Fi/{hit=1} hit && /Device:/{print $2; exit}'
}
IFACE="${IFACE:-$(get_wifi_device)}"; [ -z "$IFACE" ] && IFACE="en0"

IP=$(/usr/sbin/ipconfig getifaddr "$IFACE" 2>/dev/null || true)
if [[ -n "$IP" ]]; then
  WIFI_STATUS="Connected"; WIFI_ICON=""
else
  WIFI_STATUS="Disconnected"; WIFI_ICON=""
fi

# Сумма по всем строкам интерфейса
read IN_BYTES OUT_BYTES <<EOF
$(netstat -ibn -I "$IFACE" 2>/dev/null | awk -v iface="$IFACE" '
  NR>1 && $1==iface {inb+=$7; outb+=$10} END{if(inb=="") inb=0; if(outb=="") outb=0; print inb, outb}
')
EOF

format_bytes() {
  local bytes=${1:-0}
  if (( bytes >= 1073741824 )); then
    echo "$(bc -l <<<"scale=2;$bytes/1073741824") GB"
  elif (( bytes >= 1048576 )); then
    echo "$(bc -l <<<"scale=2;$bytes/1048576") MB"
  elif (( bytes >= 1024 )); then
    echo "$(bc -l <<<"scale=0;$bytes/1024") KB"
  else
    echo "${bytes} B"
  fi
}

IN_FORMATTED=$(format_bytes "$IN_BYTES")
OUT_FORMATTED=$(format_bytes "$OUT_BYTES")

sketchybar --set "$NAME" icon="$WIFI_ICON" label="$WIFI_STATUS"
sketchybar --set wifi.in  label="↓ $IN_FORMATTED" \
           --set wifi.out label="↑ $OUT_FORMATTED"

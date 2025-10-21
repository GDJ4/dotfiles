#!/usr/bin/env bash
# Безопасный вариант + фикс подсчёта RX/TX: суммируем все строки netstat

set -eo pipefail

# Мягкое подключение тем/иконок
[ -f "$HOME/.config/sketchybar/icons.sh" ]  && source "$HOME/.config/sketchybar/icons.sh"  || true
[ -f "$HOME/.config/sketchybar/colors.sh" ] && source "$HOME/.config/sketchybar/colors.sh" || true

: "${WIFI_ON:=}"
: "${WIFI_OFF:=}"
: "${WIFI_VPN_ON:=}"

: "${WHITE:=0xffffffff}"
: "${RED:=0xffff5555}"
: "${YELLOW:=0xffffd866}"

NAME="${NAME:-wifi}"

SB="${SKETCHYBAR_BIN:-$(command -v sketchybar || true)}"
[ -z "$SB" ] && SB="/opt/homebrew/bin/sketchybar"

get_wifi_device() {
  /usr/sbin/networksetup -listallhardwareports 2>/dev/null \
    | awk 'BEGIN{hit=0} /Hardware Port: Wi-Fi/{hit=1} hit && /Device:/{print $2; exit}'
}
get_ssid() {
  /usr/sbin/networksetup -getairportnetwork "$1" 2>/dev/null \
    | awk -F': ' '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}
vpn_is_connected() {
  /usr/sbin/scutil --nc list 2>/dev/null | grep -E '\((Connected|Connecting)\)' >/dev/null
}

format_rate() {
  local bps=${1:-0}
  if (( bps >= 1048576 )); then
    local m=$(LC_ALL=C awk -v v="$bps" 'BEGIN{printf "%.0f", v/1048576}')
    (( m == 0 )) && m=1
    printf "%sM" "$m"
  elif (( bps >= 1024 )); then
    local k=$(LC_ALL=C awk -v v="$bps" 'BEGIN{printf "%.1f", v/1024}')
    if awk "BEGIN{exit !($k >= 10)}"; then
      printf "%dK" "$(LC_ALL=C awk -v x="$k" 'BEGIN{printf "%.0f", x}')"
    else
      printf "%sK" "$k"
    fi
  else
    local k=$(LC_ALL=C awk -v v="$bps" 'BEGIN{printf "%.1f", v/1024}')
    if awk "BEGIN{exit !($k == 0)}"; then
      echo "0.0K"
    else
      printf "%sK" "$k"
    fi
  fi
}

IFACE="${IFACE:-$(get_wifi_device)}"
[ -z "$IFACE" ] && IFACE="en0"

IP=$(/usr/sbin/ipconfig getifaddr "$IFACE" 2>/dev/null || true)

if [[ -n "$IP" ]]; then
  SSID="$(get_ssid "$IFACE")"; [ -z "$SSID" ] && SSID="Unknown"
  if vpn_is_connected; then
    ICON="$WIFI_VPN_ON"
  else
    ICON="$WIFI_ON"
  fi
  COLOR="$WHITE"
  # Первичный лейбл (заменится скоростями ниже)
  LABEL="${SSID} (${IP})"
else
  ICON="$WIFI_OFF"
  LABEL="Off"
  COLOR="$RED"
fi

# --- RX/TX суммарно по всем строкам интерфейса (устойчиво ко всем адресам) ---
# Столбцы на macOS: 7=Ibytes, 10=Obytes
read CURRENT_RX CURRENT_TX <<EOF
$(netstat -ibn -I "$IFACE" 2>/dev/null | awk -v iface="$IFACE" '
  NR>1 && $1==iface {rx+=$7; tx+=$10} END{if(rx=="") rx=0; if(tx=="") tx=0; print rx, tx}
')
EOF

STATS_FILE="$HOME/.config/sketchybar/plugins/wifi_stats.txt"
if [[ -f "$STATS_FILE" ]]; then
  read -r PREV_RX PREV_TX PREV_TIME < "$STATS_FILE"
else
  PREV_RX=0; PREV_TX=0; PREV_TIME=$(date +%s)
fi

CURRENT_TIME=$(date +%s)
echo "${CURRENT_RX:-0} ${CURRENT_TX:-0} ${CURRENT_TIME}" > "$STATS_FILE"

TIME_DIFF=$(( CURRENT_TIME - PREV_TIME ))
(( TIME_DIFF == 0 )) && TIME_DIFF=1

# Защита от отрицательных (после перезагрузки счётчиков)
delta_rx=$(( CURRENT_RX - PREV_RX )); (( delta_rx < 0 )) && delta_rx=0
delta_tx=$(( CURRENT_TX - PREV_TX )); (( delta_tx < 0 )) && delta_tx=0

RX_SPEED=$(( delta_rx / TIME_DIFF ))
TX_SPEED=$(( delta_tx / TIME_DIFF ))

if [[ -n "$IP" ]]; then
  RX_FORMATTED=$(format_rate "$RX_SPEED")
  TX_FORMATTED=$(format_rate "$TX_SPEED")
  LABEL="􁾨 ${TX_FORMATTED}  􁾬 ${RX_FORMATTED}"
fi

"$SB" --set "$NAME" icon="$ICON" icon.color="$COLOR" label="$LABEL" label.color="$COLOR"
exit 0

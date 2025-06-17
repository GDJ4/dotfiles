#!/bin/bash

source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/colors.sh"

[ -z "$NAME" ] && NAME="wifi"

# Логирование для отладки
LOG_FILE="/tmp/wifi.log"
echo "Run at $(date)" >> "$LOG_FILE"

# Проверяем статус Wi-Fi через ipconfig
IP=$(ipconfig getifaddr en0 2>/dev/null)
if [ -n "$IP" ]; then
  WIFI_POWER="Connected"
  # Получаем SSID через networksetup
  SSID=$(networksetup -getairportnetwork en0 2>/dev/null | awk -F ': ' '{print $2}' | xargs)
  if [ -z "$SSID" ]; then
    SSID="Unknown"
  fi
  echo "SSID: $SSID" >> "$LOG_FILE"
  # Проверяем уровень сигнала через airport
  RSSI=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null | grep agrCtlRSSI | awk '{print $2}' | xargs)
  if [ -z "$RSSI" ]; then
    # Альтернатива: system_profiler (с осторожностью, так как тяжёлая)
    RSSI=$(system_profiler SPAirPortDataType 2>/dev/null | grep "Signal / Noise" | grep -oE "-[0-9]+" | head -1 | xargs)
    [ -z "$RSSI" ] && RSSI=-50  # Предполагаем хороший сигнал, если данные недоступны
  fi
  echo "RSSI: $RSSI" >> "$LOG_FILE"
  # Проверяем VPN через utun22
  VPN_STATUS=$(ifconfig utun22 2>/dev/null | grep -E "flags=.*UP" | wc -l)
  echo "VPN_STATUS: $VPN_STATUS" >> "$LOG_FILE"
  if [ "$VPN_STATUS" -gt 0 ]; then
    ICON="$WIFI_VPN_ON"
  else
    ICON="$WIFI_ON"
  fi
  echo "ICON: $ICON" >> "$LOG_FILE"
  LABEL="$SSID ($IP)"
  if [ "$RSSI" -lt -70 ]; then
    COLOR=$YELLOW
  else
    COLOR=$WHITE
  fi
else
  WIFI_POWER="Off"
  ICON="$WIFI_OFF"
  LABEL="Off"
  COLOR=$RED
fi

# Сетевые скорости
STATS_FILE="$HOME/.config/sketchybar/plugins/wifi_stats.txt"
if [ -f "$STATS_FILE" ]; then
  read PREV_RX PREV_TX PREV_TIME < "$STATS_FILE"
else
  PREV_RX=0
  PREV_TX=0
  PREV_TIME=$(date +%s)
fi
NETSTAT=$(netstat -ib -I en0 2>/dev/null | grep -E "en0.*[0-9]+$")
CURRENT_RX=$(echo "$NETSTAT" | awk '{print $7}')
CURRENT_TX=$(echo "$NETSTAT" | awk '{print $10}')
CURRENT_TIME=$(date +%s)

echo "$CURRENT_RX $CURRENT_TX $CURRENT_TIME" > "$STATS_FILE"

TIME_DIFF=$((CURRENT_TIME - PREV_TIME))
[ $TIME_DIFF -eq 0 ] && TIME_DIFF=1
RX_SPEED=$(((CURRENT_RX - PREV_RX) / TIME_DIFF))
TX_SPEED=$(((CURRENT_TX - PREV_TX) / TIME_DIFF))

format_speed() {
  local speed=$1
  if [ $speed -ge 1048576 ]; then
    value=$(bc -l <<< "$speed / 1048576" | awk '{printf "%.0f", $0}')
    [ $value -eq 0 ] && value=1
    printf "%-3sM" "$value"
  elif [ $speed -ge 1024 ]; then
    value=$(bc -l <<< "$speed / 1024" | awk '{printf "%.1f", $0}')
    if [ $(echo "$value >= 10" | bc -l) -eq 1 ]; then
      value=$(printf "%.0f" $value)
      echo "${value}K "
    else
      echo "${value}K"
    fi
  else
    value=$(bc -l <<< "$speed / 1024" | awk '{printf "%.1f", $0}')
    [ $(echo "$value == 0" | bc -l) -eq 1 ] && echo "0.0K" || echo "${value}K"
  fi
}

RX_FORMATTED=$(format_speed $RX_SPEED)
TX_FORMATTED=$(format_speed $TX_SPEED)

if [ "$WIFI_POWER" == "Connected" ]; then
  LABEL="􁾨 $TX_FORMATTED 􁾬 $RX_FORMATTED"
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="$LABEL" label.color="$COLOR"
exit 0
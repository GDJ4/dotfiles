#!/bin/bash

source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/colors.sh"

# Устанавливаем NAME для ручного запуска
[ -z "$NAME" ] && NAME="wifi"

# Проверяем статус Wi-Fi через system_profiler
WIFI_INFO=$(system_profiler SPAirPortDataType)
WIFI_POWER=$(echo "$WIFI_INFO" | grep -E "Status:.*Connected|Status:.*Off" | cut -d ":" -f2 | xargs)
RSSI=$(echo "$WIFI_INFO" | grep "Signal / Noise" | grep -oE "-[0-9]+" | head -1 | xargs)

# Проверяем статус Amnezia VPN через ifconfig (интерфейс utun22)
VPN_STATUS=$(ifconfig | grep -E "^utun22:.*UP")
if [ -n "$VPN_STATUS" ] && [[ "$WIFI_POWER" == "Connected" ]]; then
  ICON="$WIFI_VPN_ON"  # Иконка Wi-Fi с VPN
else
  ICON="$WIFI_ON"      # Обычная иконка Wi-Fi
fi

# Файл для хранения предыдущих значений сетевой статистики
STATS_FILE="$HOME/.config/sketchybar/plugins/wifi_stats.txt"

# Получаем текущую статистику для интерфейса en0
NETSTAT=$(netstat -ib -I en0 | grep -E "en0.*[0-9]+$")
CURRENT_RX=$(echo "$NETSTAT" | awk '{print $7}')  # Полученные байты (input bytes)
CURRENT_TX=$(echo "$NETSTAT" | awk '{print $10}') # Отправленные байты (output bytes)
CURRENT_TIME=$(date +%s)

# Читаем предыдущие значения
if [ -f "$STATS_FILE" ]; then
  read PREV_RX PREV_TX PREV_TIME < "$STATS_FILE"
else
  PREV_RX=0
  PREV_TX=0
  PREV_TIME=$CURRENT_TIME
fi

# Сохраняем текущие значения
echo "$CURRENT_RX $CURRENT_TX $CURRENT_TIME" > "$STATS_FILE"

# Вычисляем скорость (байты в секунду)
TIME_DIFF=$((CURRENT_TIME - PREV_TIME))
if [ $TIME_DIFF -eq 0 ]; then
  TIME_DIFF=1  # Избегаем деления на ноль
fi
RX_SPEED=$(((CURRENT_RX - PREV_RX) / TIME_DIFF))
TX_SPEED=$(((CURRENT_TX - PREV_TX) / TIME_DIFF))

# Форматируем скорость (всегда 4 символа)
format_speed() {
  local speed=$1
  if [ $speed -ge 1048576 ]; then  # ≥ 1 MB
    value=$(bc -l <<< "$speed / 1048576" | awk '{printf "%.0f", $0}')
    [ $value -eq 0 ] && value=1
    printf "%-3sM" "$value"  # Например, "1 M", "10M"
  elif [ $speed -ge 1024 ]; then  # ≥ 1 KB
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

# Определяем цвет иконки по уровню сигнала
if [[ "$WIFI_POWER" == "Connected" ]]; then
  LABEL="􁾨 $TX_FORMATTED 􁾬 $RX_FORMATTED"
  if [ -n "$RSSI" ] && [ "$RSSI" -lt -70 ]; then
    COLOR=$YELLOW  # Нестабильный Wi-Fi (RSSI < -70 dBm)
  else
    COLOR=$WHITE
  fi
else
  ICON="$WIFI_OFF"  # Иконка для выключенного Wi-Fi
  LABEL="Off"
  COLOR=$RED
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="$LABEL" label.color="$COLOR"
#!/bin/bash

# Проверка статуса Wi-Fi
WIFI_STATUS=$(networksetup -getairportnetwork en0 | grep "You are not associated" > /dev/null && echo "Disconnected" || echo "Connected")
WIFI_ICON=$([[ "$WIFI_STATUS" == "Connected" ]] && echo "" || echo "")

# Получение статистики трафика (в байтах)
NET_STAT=$(netstat -ib -I en0 | grep -A 1 "Name")
IN_BYTES=$(echo "$NET_STAT" | tail -1 | awk '{print $7}')
OUT_BYTES=$(echo "$NET_STAT" | tail -1 | awk '{print $10}')

# Форматирование чисел
format_bytes() {
  local bytes=$1
  if [ $bytes -gt 1073741824 ]; then
    echo "$(echo "scale=2; $bytes/1073741824" | bc) GB"
  elif [ $bytes -gt 1048576 ]; then
    echo "$(echo "scale=2; $bytes/1048576" | bc) MB"
  elif [ $bytes -gt 1024 ]; then
    echo "$(echo "scale=2; $bytes/1024" | bc) KB"
  else
    echo "$bytes B"
  fi
}

IN_FORMATTED=$(format_bytes $IN_BYTES)
OUT_FORMATTED=$(format_bytes $OUT_BYTES)

# Обновление основного элемента
sketchybar --set $NAME icon="$WIFI_ICON" label="$WIFI_STATUS"

# Обновление попапа
sketchybar --set wifi.in label="↓ $IN_FORMATTED" \
           --set wifi.out label="↑ $OUT_FORMATTED"

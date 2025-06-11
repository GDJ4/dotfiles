#!/bin/bash

# Скрипт для переключения попапа
POPUP_CLICK_SCRIPT="sketchybar --set \$NAME popup.drawing=toggle"

# Функция для получения данных о Wi-Fi и трафике
wifi_status=(
  update_freq=5
  icon.font="$FONT:Bold:15.0"
  icon=
  icon.color=$WHITE
  label="Checking..."
  label.highlight_color=$BLUE
  popup.align=right
  script="$PLUGIN_DIR/wifi_status.sh"
  click_script="$POPUP_CLICK_SCRIPT"
)

wifi_template=(
  drawing=off
  background.corner_radius=12
  padding_left=7
  padding_right=7
  icon.background.height=2
  icon.background.y_offset=-12
)

# Скрипт для получения статуса и трафика
cat << 'EOF' > $PLUGIN_DIR/wifi_status.sh
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
EOF

# Делаем скрипт исполняемым
chmod +x $PLUGIN_DIR/wifi_status.sh

# Добавление элементов в sketchybar
sketchybar --add item wifi.status right                \
           --set wifi.status "${wifi_status[@]}"       \
           --subscribe wifi.status mouse.entered       \
                                  mouse.exited         \
                                  mouse.exited.global  \
                                                       \
           --add item wifi.in popup.wifi.status        \
           --set wifi.in label="↓ 0 B"                \
                         padding_left=10              \
                         padding_right=10             \
                         background.corner_radius=8   \
                                                       \
           --add item wifi.out popup.wifi.status       \
           --set wifi.out label="↑ 0 B"               \
                          padding_left=10             \
                          padding_right=10            \
                          background.corner_radius=8  \
                                                       \
           --add item wifi.template popup.wifi.status  \
           --set wifi.template "${wifi_template[@]}"
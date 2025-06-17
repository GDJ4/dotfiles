#!/bin/bash

wifi=(
  script="$PLUGIN_DIR/wifi.sh"
  icon.font="$FONT:Regular:19.0"      # Иконка остаётся без изменений
  label.font="Menlo:Regular:10.0"     # Моноширинный шрифт
  label.width=90                     # Фиксированная ширина метки (в пикселях)
  label.align=center                  # Выравнивание текста по центру
  padding_right=5
  padding_left=5
  update_freq=7
  updates=on
)

sketchybar --add item wifi right      \
           --set wifi "${wifi[@]}"    \
           --subscribe wifi system_woke
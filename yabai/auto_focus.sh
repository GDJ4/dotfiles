#!/bin/sh
# Получаем ID фокусированного окна (если есть)
focused=$(yabai -m query --windows --window 2>/dev/null | jq -r '.id')

# Если фокус отсутствует, выбираем первое окно на текущем пространстве
if [ -z "$focused" ]; then
  next_window=$(yabai -m query --windows --space | jq '.[0].id')
  if [ -n "$next_window" ]; then
    yabai -m window --focus "$next_window"
  fi
fi

#!/bin/sh

event="${1:-check}"
signal_window_id="${YABAI_WINDOW_ID:-}"

if [ "$event" = "created" ] && [ -n "$signal_window_id" ]; then
  yabai -m window --focus "$signal_window_id" >/dev/null 2>&1 && exit 0
fi

# На destroy/terminate даем yabai закончить обновление дерева окон.
if [ "$event" = "destroyed" ] || [ "$event" = "terminated" ]; then
  sleep 0.12
fi

focused="$(yabai -m query --windows --window 2>/dev/null | jq -er '.id // empty' 2>/dev/null || true)"
if [ -n "$focused" ] && [ "$focused" != "$signal_window_id" ]; then
  exit 0
fi

# Сначала пытаемся вернуть фокус на "последнее живое" окно.
yabai -m window --focus recent >/dev/null 2>&1 && exit 0

# Если recent недоступен, берем первое окно на текущем space.
next_window="$(yabai -m query --windows --space 2>/dev/null | jq -er '.[0].id // empty' 2>/dev/null || true)"
if [ -n "$next_window" ] && [ "$next_window" != "$signal_window_id" ]; then
  yabai -m window --focus "$next_window" >/dev/null 2>&1
fi

#!/bin/bash

if [ -z "$INFO" ]; then
  INFO="$(yabai -m query --windows --window 2>/dev/null | jq -r '.app // empty')"
fi

APP_ICON="$("$HOME/.config/sketchybar/plugins/icon_map.sh" "${INFO:-Default}")"

sketchybar --set "$NAME" icon="$APP_ICON"

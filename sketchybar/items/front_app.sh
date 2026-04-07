#!/bin/bash

yabai=(
  script="$PLUGIN_DIR/yabai.sh"
  updates=on
  icon.drawing=off
  icon.width=0
  label.drawing=off
  width=0
  padding_left=0
  padding_right=0
  background.drawing=off
  associated_display=active
)

front_app=(
  script="$PLUGIN_DIR/front_app.sh"
  icon.drawing=on
  icon="$($PLUGIN_DIR/icon_map.sh "Default")"
  icon.font="sketchybar-app-font:Regular:16.0"
  icon.color=$WHITE
  icon.padding_left=0
  icon.padding_right=0
  label.drawing=off
  width=30
  padding_left=2
  label.color=$WHITE
  label.font="$FONT:Black:12.0"
  associated_display=active
)

sketchybar --add event window_focus            \
           --add event windows_on_spaces       \
           --add item yabai left               \
           --set yabai "${yabai[@]}"           \
           --subscribe yabai window_focus      \
                             windows_on_spaces \
                                               \
           --add item front_app left           \
           --set front_app "${front_app[@]}"   \
           --subscribe front_app front_app_switched \
                                 window_focus

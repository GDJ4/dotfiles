#!/bin/sh

DESIRED_SPACES_PER_DISPLAY=4

yabai -m query --displays | jq -r '.[] | "\(.index) \(.spaces | length)"' |
while read -r DISPLAY_INDEX EXISTING_SPACE_COUNT
do
  MISSING_SPACES=$(($DESIRED_SPACES_PER_DISPLAY - $EXISTING_SPACE_COUNT))
  if [ "$MISSING_SPACES" -gt 0 ]; then
    for i in $(seq 1 $MISSING_SPACES)
    do
      yabai -m space --create "$DISPLAY_INDEX"
    done
  elif [ "$MISSING_SPACES" -lt 0 ]; then
    for i in $(seq 1 $((-$MISSING_SPACES)))
    do
      LAST_SPACE="$(yabai -m query --spaces --display "$DISPLAY_INDEX" | jq -r '.[-1].index')"
      yabai -m space --destroy "$LAST_SPACE"
    done
  fi
done

sketchybar --trigger space_change --trigger windows_on_spaces

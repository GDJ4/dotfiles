#!/usr/bin/env bash

# Toggle presentation spacing, terminal font size and wallpaper.
# Override the wallpaper paths when needed, for example:
#   PRESENTATION_WALLPAPER="$HOME/Pictures/talk.png" \
#   NORMAL_WALLPAPER="$HOME/Pictures/default.png" \
#   ./presentation.sh on

set -euo pipefail

presentation_pixel_gaps=300
top_normal_pixel_gaps=82
bottom_normal_pixel_gaps=10
terminal_font_size=18
terminal_presentation_font_size=22

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
aerospace_config="$config_dir/aerospace/aerospace.toml"
alacritty_config="$config_dir/alacritty/alacritty.toml"

presentation_wallpaper="${PRESENTATION_WALLPAPER:-$HOME/Pictures/Wallpapers/presentation.png}"
normal_wallpaper="${NORMAL_WALLPAPER:-$HOME/Pictures/Wallpapers/default.png}"

set_gap() {
  local name="$1"
  local value="$2"
  sed -i '' -E "s|(${name} = .*, )[0-9]+ *]|\1${value}]|" "$aerospace_config"
}

set_terminal_size() {
  local value="$1"
  sed -i '' -E "s|^size[[:space:]]*=.*|size = ${value}|" "$alacritty_config"
}

set_wallpaper() {
  local wallpaper="$1"
  if [ -f "$wallpaper" ]; then
    osascript -e "tell application \"System Events\" to set picture of every desktop to POSIX file \"$wallpaper\""
  else
    printf 'Wallpaper not found, keeping the current wallpaper: %s\n' "$wallpaper" >&2
  fi
}

case "${1:-}" in
  on)
    set_gap 'outer\.top' "$presentation_pixel_gaps"
    set_gap 'outer\.bottom' "$presentation_pixel_gaps"
    set_terminal_size "$terminal_presentation_font_size"
    set_wallpaper "$presentation_wallpaper"
    aerospace reload-config
    ;;
  off)
    set_gap 'outer\.top' "$top_normal_pixel_gaps"
    set_gap 'outer\.bottom' "$bottom_normal_pixel_gaps"
    set_terminal_size "$terminal_font_size"
    set_wallpaper "$normal_wallpaper"
    aerospace reload-config
    ;;
  *)
    printf 'Usage: %s {on|off}\n' "$0" >&2
    exit 2
    ;;
esac

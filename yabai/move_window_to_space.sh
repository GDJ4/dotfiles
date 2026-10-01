#!/bin/sh

# yabai 7.1.25+ uses SLSBridgedMoveWindowsToManagedSpaceOperation on macOS
# 26.4+, but on 26.6.2 that call can succeed without moving the window.
# Send the existing scripting-addition command directly until yabai fixes it.

set -eu

SPACE_SELECTOR="${1:?usage: move_window_to_space.sh SPACE_SELECTOR [--focus]}"
FOLLOW_FOCUS="${2:-}"

WINDOW="$(yabai -m query --windows --window)"
WINDOW_ID="$(printf '%s\n' "$WINDOW" | jq -er '.id')"
SOURCE_SPACE_INDEX="$(printf '%s\n' "$WINDOW" | jq -er '.space')"
TARGET_SPACE="$(yabai -m query --spaces --space "$SPACE_SELECTOR")"
TARGET_SPACE_ID="$(printf '%s\n' "$TARGET_SPACE" | jq -er '.id')"
TARGET_SPACE_INDEX="$(printf '%s\n' "$TARGET_SPACE" | jq -er '.index')"
SOCKET_PATH="/tmp/yabai-sa_$(id -un).socket"

[ "$SOURCE_SPACE_INDEX" = "$TARGET_SPACE_INDEX" ] && exit 0

# Re-apply a space's own layout. yabai rebuilds the window tree from a live
# query on this command, which is what drops stale nodes and re-tiles.
resync_space() {
  space_index="$1"
  layout="$(yabai -m query --spaces --space "$space_index" | jq -er '.type')"
  case "$layout" in
    bsp|stack) yabai -m space "$space_index" --layout "$layout" ;;
  esac
}

/usr/bin/ruby -rsocket -e '
  socket_path, space_id, window_id = ARGV
  socket = UNIXSocket.new(socket_path)
  socket.write([13, 0x13, Integer(space_id), Integer(window_id)].pack("s<CQ<L<"))
  # The payload does not send a response for this opcode. Waiting for EOF can
  # block while the Dock-side operation completes, so verify through yabai below.
  socket.close
' "$SOCKET_PATH" "$TARGET_SPACE_ID" "$WINDOW_ID"

# The scripting-addition operation is asynchronous. Wait until yabai has
# observed it before optionally following the window to its new space.
ATTEMPT=0
while [ "$(yabai -m query --windows --window "$WINDOW_ID" | jq -er '.space')" != "$TARGET_SPACE_INDEX" ]; do
  ATTEMPT=$((ATTEMPT + 1))
  if [ "$ATTEMPT" -ge 20 ]; then
    echo "window $WINDOW_ID did not move to space $TARGET_SPACE_INDEX" >&2
    exit 1
  fi
  sleep 0.05
done

# The scripting addition moves the window behind yabai's back: the source tree
# keeps a stale node (neighbours never grow into the freed slot) and the target
# tree never gains one (the window lands unmanaged, overlapping whatever is
# there). Rebuild both trees so the layout matches reality.
resync_space "$SOURCE_SPACE_INDEX"

# macOS does not reposition windows on an inactive space, so resync the target
# only once it is visible; otherwise yabai re-validates it on the next focus.
if [ "$FOLLOW_FOCUS" = "--focus" ]; then
  yabai -m space --focus "$TARGET_SPACE_INDEX"
  resync_space "$TARGET_SPACE_INDEX"
  yabai -m window --focus "$WINDOW_ID"
elif [ "$(yabai -m query --spaces --space "$TARGET_SPACE_INDEX" | jq -er '."is-visible"')" = "true" ]; then
  resync_space "$TARGET_SPACE_INDEX"
fi

#!/usr/bin/env bash
# waybar-autohide.sh — Hide waybar on workspaces that have windows,
# show it on empty workspaces. Listens to Hyprland IPC events.
# Runs as an external process, does NOT touch Hyprland internals.

set -euo pipefail

SOCKET_PATH="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
STATE_FILE="/tmp/waybar_hidden_${HYPRLAND_INSTANCE_SIGNATURE}"

# Clean up stale state on start
rm -f "$STATE_FILE"

# --- Helper functions ---

get_window_count() {
    # Returns the window count of the currently active workspace
    hyprctl activeworkspace -j 2>/dev/null | grep -o '"windows": *[0-9]*' | grep -o '[0-9]*'
}

hide_waybar() {
    if [ ! -f "$STATE_FILE" ]; then
        pkill -SIGUSR1 waybar 2>/dev/null || true
        touch "$STATE_FILE"
    fi
}

show_waybar() {
    if [ -f "$STATE_FILE" ]; then
        pkill -SIGUSR1 waybar 2>/dev/null || true
        rm -f "$STATE_FILE"
    fi
}

update_waybar() {
    local count
    count=$(get_window_count)
    if [ -n "$count" ] && [ "$count" -gt 0 ]; then
        hide_waybar
    else
        show_waybar
    fi
}

# --- Initial check ---
# Small delay to let waybar fully start on first boot
sleep 1
update_waybar

# --- Event loop ---
# Listen to Hyprland IPC socket for relevant events
nc -U "$SOCKET_PATH" 2>/dev/null | while IFS= read -r event; do
    case "$event" in
        workspace\>\>*|openwindow\>\>*|closewindow\>\>*|movewindow\>\>*)
            # Small debounce: skip if another event arrives within 100ms
            sleep 0.1
            update_waybar
            ;;
    esac
done

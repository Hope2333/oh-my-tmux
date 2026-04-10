#!/usr/bin/env bash
set -euo pipefail

tmux_bin="${TMUX_PROGRAM:-tmux}"
socket_args=()
if [ -n "${TMUX_SOCKET:-}" ]; then
	socket_args=(-S "$TMUX_SOCKET")
fi

updater="$HOME/.config/tmux/omt-perf/update-pane-cache.sh"
per_pane_delay="${OMT_PANE_REFRESH_DELAY:-0.02}"

while IFS= read -r pane_id; do
	[ -n "$pane_id" ] || continue
	"$updater" "$pane_id" || true
	sleep "$per_pane_delay"
done < <($tmux_bin "${socket_args[@]}" list-panes -s -F '#{pane_id}' | sort -u)

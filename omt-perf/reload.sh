#!/usr/bin/env bash
set -euo pipefail

tmux_bin="${TMUX_PROGRAM:-tmux}"
socket_args=()
if [ -n "${TMUX_SOCKET:-}" ]; then
	socket_args=(-S "$TMUX_SOCKET")
fi

tmux_conf="${TMUX_CONF:-}"
if [ -z "$tmux_conf" ]; then
	if [ -f "$HOME/.config/tmux/tmux.conf" ]; then
		tmux_conf="$HOME/.config/tmux/tmux.conf"
	elif [ -f "$HOME/.tmux.conf" ]; then
		tmux_conf="$HOME/.tmux.conf"
	else
		tmux_conf="$HOME/.config/tmux/tmux.conf"
	fi
fi

"$tmux_bin" "${socket_args[@]}" source-file "$tmux_conf"
"$HOME/.config/tmux/omt-perf/apply.sh"

"$tmux_bin" "${socket_args[@]}" display-message 'tmux reloaded + omt-perf Phase A applied'

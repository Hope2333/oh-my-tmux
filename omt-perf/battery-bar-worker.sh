#!/usr/bin/env bash
set -euo pipefail

tmux_bin="${TMUX_PROGRAM:-tmux}"
socket_args=()
if [ -n "${TMUX_SOCKET:-}" ]; then
	socket_args=(-S "$TMUX_SOCKET")
fi

charge="${1:-}"
client_width="${2:-80}"
if [ -z "$charge" ]; then
	charge="$($tmux_bin "${socket_args[@]}" show-option -gv @battery_charge 2>/dev/null || true)"
	if [ -z "$charge" ]; then
		exit 0
	fi
fi

cache_root="${XDG_CACHE_HOME:-$HOME/.cache}"
cache_dir="$cache_root/tmux/battery-bar"
mkdir -p "$cache_dir"

cache_file="$cache_dir/${charge}_${client_width}"
if [ -r "$cache_file" ]; then
	cat "$cache_file"
	exit 0
fi

omt_sh="${XDG_CACHE_HOME:-$HOME/.cache}/tmux/omt.sh"
bar=""
if [ -x "$omt_sh" ]; then
	bar="$(nice sh "$omt_sh" _bar gradient ◻ ◼ auto "$charge" "$client_width" 2>/dev/null || true)"
fi

printf '%s' "$bar" >"$cache_file"
cat "$cache_file"

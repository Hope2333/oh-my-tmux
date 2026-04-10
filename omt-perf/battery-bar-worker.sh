#!/usr/bin/env bash
set -euo pipefail

tmux_bin="${TMUX_PROGRAM:-tmux}"
socket_args=()
if [ -n "${TMUX_SOCKET:-}" ]; then
	socket_args=(-S "$TMUX_SOCKET")
fi

charge="${1:-}"
client_width="${2:-}"
if [ -z "$charge" ]; then
	charge="$($tmux_bin "${socket_args[@]}" show-option -gv @battery_charge 2>/dev/null || true)"
	if [ -z "$charge" ]; then
		exit 0
	fi
fi

cache_root="${XDG_CACHE_HOME:-$HOME/.cache}"
cache_dir="$cache_root/tmux/battery-bar"
mkdir -p "$cache_dir"

# Check if battery is low (<18%)
if (($(echo "$charge < 0.18" | bc -l 2>/dev/null || echo 0))); then
	palette="#d70000,#d70000,#2f343f"
else
	palette="#5294e2,#5294e2,#2f343f"
fi

cache_file="$cache_dir/${charge}_${client_width}"
if [ -r "$cache_file" ]; then
	cat "$cache_file"
	exit 0
fi

omt_sh="${XDG_CACHE_HOME:-$HOME/.cache}/tmux/omt.sh"
bar=""
if [ -x "$omt_sh" ]; then
	bar="$(nice sh "$omt_sh" _bar "$palette" ◻ ◼ auto "$charge" "$client_width" 2>/dev/null || true)"
fi

printf '%s' "$bar" >"$cache_file"
cat "$cache_file"

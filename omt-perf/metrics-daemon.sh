#!/usr/bin/env bash
set -euo pipefail

tmux_bin="${TMUX_PROGRAM:-tmux}"
socket_args=()
if [ -n "${TMUX_SOCKET:-}" ]; then
	socket_args=(-S "$TMUX_SOCKET")
fi

tmux_conf="${TMUX_CONF:-$HOME/.config/tmux/tmux.conf}"

cache_root="${XDG_CACHE_HOME:-$HOME/.cache}"
cache_dir="$cache_root/tmux"
lock_file="$cache_dir/omt-metrics.lock"
mkdir -p "$cache_dir"

if ! flock -n "$lock_file" -c true; then
	exit 0
fi

flock -n "$lock_file" bash -s <<'BASH'
set -euo pipefail

tmux_bin="${TMUX_PROGRAM:-tmux}"
socket_args=()
if [ -n "${TMUX_SOCKET:-}" ]; then
	socket_args=(-S "$TMUX_SOCKET")
fi

tmux_conf="${TMUX_CONF:-$HOME/.config/tmux/tmux.conf}"
omt_sh="${XDG_CACHE_HOME:-$HOME/.cache}/tmux/omt.sh"
battery_worker="$HOME/.config/tmux/omt-perf/battery-bar-worker.sh"
metrics_interval_sec="${OMT_METRICS_INTERVAL_SEC:-75}"
width_stagger_sec="${OMT_WIDTH_STAGGER_SEC:-0.03}"

while [ "$("$tmux_bin" "${socket_args[@]}" display-message -p '#{pid}' 2>/dev/null || true)" != "" ]; do
	if [ -x "$omt_sh" ]; then
		sh "$omt_sh" _battery_info >/dev/null 2>&1 || true
		sh "$omt_sh" _uptime >/dev/null 2>&1 || true
		battery_charge="$("$tmux_bin" "${socket_args[@]}" show-option -gv @battery_charge 2>/dev/null || true)"
		if [ -n "$battery_charge" ] && [ -x "$battery_worker" ]; then
			while IFS= read -r width; do
				[ -n "$width" ] || continue
				sh "$battery_worker" "$battery_charge" "$width" >/dev/null 2>&1 || true
				sleep "$width_stagger_sec"
			done < <("$tmux_bin" "${socket_args[@]}" list-clients -F '#{client_width}' | sort -u)
		fi
	fi
	sleep "$metrics_interval_sec"
	[ "$("$tmux_bin" "${socket_args[@]}" display-message -p '#{pid}' 2>/dev/null || true)" != "" ] || exit 0
done
BASH

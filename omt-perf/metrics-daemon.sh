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
refresh_battery_bar="$HOME/.config/tmux/omt-perf/refresh-battery-bar.sh"
metrics_interval_sec="${OMT_METRICS_INTERVAL_SEC:-75}"

while [ "$("$tmux_bin" "${socket_args[@]}" display-message -p '#{pid}' 2>/dev/null || true)" != "" ]; do
	if [ -x "$omt_sh" ]; then
		sh "$omt_sh" _battery_info >/dev/null 2>&1 || true
		sh "$omt_sh" _battery_status "↑" "↓" >/dev/null 2>&1 || true
		sh "$omt_sh" _uptime >/dev/null 2>&1 || true
		battery_charge="$("$tmux_bin" "${socket_args[@]}" show-option -gv @battery_charge 2>/dev/null || true)"
		battery_status="$("$tmux_bin" "${socket_args[@]}" show-option -gv @battery_status 2>/dev/null || true)"
		battery_pct="$("$tmux_bin" "${socket_args[@]}" show-option -gv @battery_percentage 2>/dev/null || true)"
		if [ -n "$battery_status" ]; then
			"$tmux_bin" "${socket_args[@]}" set-option -g @omt_battery_status "$battery_status"
		else
			"$tmux_bin" "${socket_args[@]}" set-option -gu @omt_battery_status >/dev/null 2>&1 || true
		fi
		if [ -n "$battery_pct" ]; then
			"$tmux_bin" "${socket_args[@]}" set-option -g @omt_battery_pct "$battery_pct"
		else
			"$tmux_bin" "${socket_args[@]}" set-option -gu @omt_battery_pct >/dev/null 2>&1 || true
		fi
		if [ -x "$refresh_battery_bar" ]; then
			"$refresh_battery_bar" >/dev/null 2>&1 || true
		fi
	fi
	sleep "$metrics_interval_sec"
	[ "$("$tmux_bin" "${socket_args[@]}" display-message -p '#{pid}' 2>/dev/null || true)" != "" ] || exit 0
done
BASH

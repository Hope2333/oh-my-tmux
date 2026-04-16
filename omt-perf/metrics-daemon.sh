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
metrics_interval_sec="${OMT_METRICS_INTERVAL_SEC:-75}"

set_battery_bar() {
	local battery_charge="$1"
	local palette low_palette empty_symbol full_symbol bar_length client_width bar

	if [ -z "$battery_charge" ]; then
		"$tmux_bin" "${socket_args[@]}" set-option -gu @omt_battery_bar >/dev/null 2>&1 || true
		return 0
	fi

	palette="$("$tmux_bin" "${socket_args[@]}" show-option -gv @omt_battery_bar_palette 2>/dev/null || true)"
	low_palette="$("$tmux_bin" "${socket_args[@]}" show-option -gv @omt_battery_bar_low_palette 2>/dev/null || true)"
	empty_symbol="$("$tmux_bin" "${socket_args[@]}" show-option -gv @omt_battery_bar_symbol_empty 2>/dev/null || true)"
	full_symbol="$("$tmux_bin" "${socket_args[@]}" show-option -gv @omt_battery_bar_symbol_full 2>/dev/null || true)"
	bar_length="$("$tmux_bin" "${socket_args[@]}" show-option -gv @omt_battery_bar_length 2>/dev/null || true)"

	[ -n "$palette" ] || palette="gradient"
	[ -n "$empty_symbol" ] || empty_symbol="◻"
	[ -n "$full_symbol" ] || full_symbol="◼"
	[ -n "$bar_length" ] || bar_length="8"

	if [ -n "$low_palette" ] && (($(echo "$battery_charge < 0.18" | bc -l 2>/dev/null || echo 0))); then
		palette="$low_palette"
	fi
	palette="${palette//,/;}"

	client_width="$("$tmux_bin" "${socket_args[@]}" list-clients -F '#{client_width}' 2>/dev/null | sort -nr | sed -n '1p' || true)"
	[ -n "$client_width" ] || client_width="80"

	bar="$(sh "$omt_sh" _bar "$palette" "$empty_symbol" "$full_symbol" "$bar_length" "$battery_charge" "$client_width" 2>/dev/null || true)"
	if [ -n "$bar" ]; then
		"$tmux_bin" "${socket_args[@]}" set-option -g @omt_battery_bar "$bar"
	else
		"$tmux_bin" "${socket_args[@]}" set-option -gu @omt_battery_bar >/dev/null 2>&1 || true
	fi
}

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
		set_battery_bar "$battery_charge"
	fi
	sleep "$metrics_interval_sec"
	[ "$("$tmux_bin" "${socket_args[@]}" display-message -p '#{pid}' 2>/dev/null || true)" != "" ] || exit 0
done
BASH

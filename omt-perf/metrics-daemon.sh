#!/usr/bin/env bash
set -euo pipefail

tmux_bin="${TMUX_PROGRAM:-tmux}"
socket_args=()
if [ -n "${TMUX_SOCKET:-}" ]; then
	socket_args=(-S "$TMUX_SOCKET")
fi

tmux_conf="${TMUX_CONF:-$HOME/.config/tmux/tmux.conf}"
mode="${1:-daemon}"

cache_root="${XDG_CACHE_HOME:-$HOME/.cache}"
cache_dir="$cache_root/tmux"
lock_file="$cache_dir/omt-metrics.lock"
mkdir -p "$cache_dir"

if [ "$mode" != "--once" ]; then
	exec 9>"$lock_file"
	if ! flock -n 9; then
		exit 0
	fi
	mode="daemon"
else
	mode="once"
fi

omt_sh="${XDG_CACHE_HOME:-$HOME/.cache}/tmux/omt.sh"
metrics_interval_sec="${OMT_METRICS_INTERVAL_SEC:-75}"

tmux_get() {
	"$tmux_bin" "${socket_args[@]}" show-option -gv "$1" 2>/dev/null || true
}

tmux_set() {
	"$tmux_bin" "${socket_args[@]}" set-option -g "$1" "$2"
}

tmux_unset() {
	"$tmux_bin" "${socket_args[@]}" set-option -gu "$1" >/dev/null 2>&1 || true
}

client_width_floor() {
	local width
	width="$("$tmux_bin" "${socket_args[@]}" list-clients -F '#{client_width}' 2>/dev/null | sort -n | sed -n '1p' || true)"
	[ -n "$width" ] || width="80"
	printf '%s' "$width"
}

set_status_tiers() {
	local client_width show_pct_under show_date_under show_user_under

	client_width="$1"
	show_pct_under="$(tmux_get @omt_status_hide_battery_pct_under)"
	show_date_under="$(tmux_get @omt_status_hide_date_under)"
	show_user_under="$(tmux_get @omt_status_hide_user_under)"

	[ -n "$show_pct_under" ] || show_pct_under="64"
	[ -n "$show_date_under" ] || show_date_under="112"
	[ -n "$show_user_under" ] || show_user_under="96"

	if [ "$client_width" -lt "$show_pct_under" ]; then
		tmux_unset @omt_status_show_battery_pct
	else
		tmux_set @omt_status_show_battery_pct 1
	fi

	if [ "$client_width" -lt "$show_date_under" ]; then
		tmux_unset @omt_status_show_date
	else
		tmux_set @omt_status_show_date 1
	fi

	if [ "$client_width" -lt "$show_user_under" ]; then
		tmux_unset @omt_status_show_user
	else
		tmux_set @omt_status_show_user 1
	fi
}

set_battery_bar() {
	local battery_charge="$1"
	local client_width="$2"
	local palette low_palette empty_symbol full_symbol bar_length bar
	local hide_under small_under medium_under small_length medium_length

	if [ -z "$battery_charge" ]; then
		tmux_unset @omt_battery_bar
		return 0
	fi

	hide_under="$(tmux_get @omt_battery_bar_hide_under)"
	small_under="$(tmux_get @omt_battery_bar_small_under)"
	medium_under="$(tmux_get @omt_battery_bar_medium_under)"
	bar_length="$(tmux_get @omt_battery_bar_length)"
	medium_length="$(tmux_get @omt_battery_bar_medium_length)"
	small_length="$(tmux_get @omt_battery_bar_small_length)"

	[ -n "$hide_under" ] || hide_under="88"
	[ -n "$small_under" ] || small_under="112"
	[ -n "$medium_under" ] || medium_under="140"
	[ -n "$bar_length" ] || bar_length="8"
	[ -n "$medium_length" ] || medium_length="6"
	[ -n "$small_length" ] || small_length="4"

	if [ "$client_width" -lt "$hide_under" ]; then
		tmux_unset @omt_battery_bar
		return 0
	elif [ "$client_width" -lt "$small_under" ]; then
		bar_length="$small_length"
	elif [ "$client_width" -lt "$medium_under" ]; then
		bar_length="$medium_length"
	fi

	palette="$(tmux_get @omt_battery_bar_palette)"
	low_palette="$(tmux_get @omt_battery_bar_low_palette)"
	empty_symbol="$(tmux_get @omt_battery_bar_symbol_empty)"
	full_symbol="$(tmux_get @omt_battery_bar_symbol_full)"

	[ -n "$palette" ] || palette="gradient"
	[ -n "$empty_symbol" ] || empty_symbol="◻"
	[ -n "$full_symbol" ] || full_symbol="◼"

	if [ -n "$low_palette" ] && (($(echo "$battery_charge < 0.18" | bc -l 2>/dev/null || echo 0))); then
		palette="$low_palette"
	fi
	palette="${palette//,/;}"

	bar="$(sh "$omt_sh" _bar "$palette" "$empty_symbol" "$full_symbol" "$bar_length" "$battery_charge" "$client_width" 2>/dev/null || true)"
	if [ -n "$bar" ]; then
		tmux_set @omt_battery_bar "$bar"
	else
		tmux_unset @omt_battery_bar
	fi
}

update_metrics() {
	local battery_charge battery_status battery_pct client_width

	if [ -x "$omt_sh" ]; then
		sh "$omt_sh" _battery_info >/dev/null 2>&1 || true
		sh "$omt_sh" _battery_status "↑" "↓" >/dev/null 2>&1 || true
		sh "$omt_sh" _uptime >/dev/null 2>&1 || true
		battery_charge="$(tmux_get @battery_charge)"
		battery_status="$(tmux_get @battery_status)"
		battery_pct="$(tmux_get @battery_percentage)"
		client_width="$(client_width_floor)"
		set_status_tiers "$client_width"

		if [ -n "$battery_status" ]; then
			tmux_set @omt_battery_status "$battery_status"
		else
			tmux_unset @omt_battery_status
		fi
		if [ -n "$battery_charge" ] && [ -n "$battery_pct" ]; then
			if (($(echo "$battery_charge < 0.18" | bc -l 2>/dev/null || echo 0))); then
				tmux_set @omt_battery_pct "#[fg=#d70000]${battery_pct}"
			else
				tmux_set @omt_battery_pct "#[fg=#5294e2]${battery_pct}"
			fi
		elif [ -n "$battery_pct" ]; then
			tmux_set @omt_battery_pct "$battery_pct"
		else
			tmux_unset @omt_battery_pct
		fi
		set_battery_bar "$battery_charge" "$client_width"
	fi
}

if [ "$mode" = "once" ]; then
	update_metrics
	exit 0
fi

while [ "$("$tmux_bin" "${socket_args[@]}" display-message -p '#{pid}' 2>/dev/null || true)" != "" ]; do
	update_metrics
	sleep "$metrics_interval_sec"
	[ "$("$tmux_bin" "${socket_args[@]}" display-message -p '#{pid}' 2>/dev/null || true)" != "" ] || exit 0
done

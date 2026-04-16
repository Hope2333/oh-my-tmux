#!/usr/bin/env bash
set -euo pipefail

tmux_bin="${TMUX_PROGRAM:-tmux}"
socket_args=()
if [ -n "${TMUX_SOCKET:-}" ]; then
	socket_args=(-S "$TMUX_SOCKET")
fi

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

render_bar() {
	local charge="$1"
	local render_width="$2"
	local palette="$3"
	local empty_symbol="$4"
	local full_symbol="$5"
	local bar_length="$6"
	local omt_sh bar

	omt_sh="${XDG_CACHE_HOME:-$HOME/.cache}/tmux/omt.sh"
	if [ -z "$charge" ] || [ ! -x "$omt_sh" ]; then
		return 0
	fi

	bar="$(sh "$omt_sh" _bar "${palette//,/;}" "$empty_symbol" "$full_symbol" "$bar_length" "$charge" "$render_width" 2>/dev/null || true)"
	printf '%s' "$bar"
}

battery_charge="$(tmux_get @battery_charge)"
battery_pct="$(tmux_get @battery_percentage)"
if [ -z "$battery_charge" ] || [ -z "$battery_pct" ]; then
	tmux_unset @omt_battery_bar
	exit 0
fi

client_width="$(client_width_floor)"
hide_under="$(tmux_get @omt_battery_bar_hide_under)"
small_under="$(tmux_get @omt_battery_bar_small_under)"
medium_under="$(tmux_get @omt_battery_bar_medium_under)"
bar_length="$(tmux_get @omt_battery_bar_length)"
small_length="$(tmux_get @omt_battery_bar_small_length)"
medium_length="$(tmux_get @omt_battery_bar_medium_length)"
palette="$(tmux_get @omt_battery_bar_palette)"
low_palette="$(tmux_get @omt_battery_bar_low_palette)"
empty_symbol="$(tmux_get @omt_battery_bar_symbol_empty)"
full_symbol="$(tmux_get @omt_battery_bar_symbol_full)"

[ -n "$hide_under" ] || hide_under="80"
[ -n "$small_under" ] || small_under="96"
[ -n "$medium_under" ] || medium_under="120"
[ -n "$bar_length" ] || bar_length="8"
[ -n "$small_length" ] || small_length="4"
[ -n "$medium_length" ] || medium_length="6"
[ -n "$palette" ] || palette="gradient"
[ -n "$low_palette" ] || low_palette="heat"
[ -n "$empty_symbol" ] || empty_symbol="◻"
[ -n "$full_symbol" ] || full_symbol="◼"

if [ "$client_width" -lt "$hide_under" ]; then
	tmux_unset @omt_battery_bar
	exit 0
elif [ "$client_width" -lt "$small_under" ]; then
	bar_length="$small_length"
elif [ "$client_width" -lt "$medium_under" ]; then
	bar_length="$medium_length"
fi

if (($(echo "$battery_charge < 0.18" | bc -l 2>/dev/null || echo 0))); then
	palette="$low_palette"
fi

bar="$(render_bar "$battery_charge" "$client_width" "$palette" "$empty_symbol" "$full_symbol" "$bar_length")"
if [ -n "$bar" ]; then
	tmux_set @omt_battery_bar "$bar"
else
	tmux_unset @omt_battery_bar
fi

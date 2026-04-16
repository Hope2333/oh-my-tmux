#!/usr/bin/env bash
set -euo pipefail

tmux_bin="${TMUX_PROGRAM:-tmux}"
socket="${TMUX_SOCKET:-}"
if [ -z "$socket" ] && [ -n "${TMUX:-}" ]; then
	socket="${TMUX%%,*}"
fi

socket_args=()
if [ -n "$socket" ]; then
	socket_args=(-S "$socket")
fi

tmux_conf_local="${TMUX_CONF_LOCAL:-}"
if [ -z "$tmux_conf_local" ]; then
	if [ -f "$HOME/.config/tmux/tmux.conf.local" ]; then
		tmux_conf_local="$HOME/.config/tmux/tmux.conf.local"
	elif [ -f "$HOME/.tmux.conf.local" ]; then
		tmux_conf_local="$HOME/.tmux.conf.local"
	fi
fi

width=""
hide_under=""
small_under=""
medium_under=""
pct_under=""
user_under=""
date_under=""

while [ $# -gt 0 ]; do
	case "$1" in
	--width)
		width="${2:-}"
		shift 2
		;;
	--hide-under)
		hide_under="${2:-}"
		shift 2
		;;
	--small-under)
		small_under="${2:-}"
		shift 2
		;;
	--medium-under)
		medium_under="${2:-}"
		shift 2
		;;
	--pct-under)
		pct_under="${2:-}"
		shift 2
		;;
	--user-under)
		user_under="${2:-}"
		shift 2
		;;
	--date-under)
		date_under="${2:-}"
		shift 2
		;;
	-h | --help)
		cat <<'EOF'
Usage: render-status.sh [options]

Options:
  --width N          Render preview for client width N
  --hide-under N     Hide battery bar below width N
  --small-under N    Use short battery bar below width N
  --medium-under N   Use medium battery bar below width N
  --pct-under N      Hide battery percentage below width N
  --user-under N     Hide username/root below width N
  --date-under N     Hide date below width N
EOF
		exit 0
		;;
	*)
		printf 'unknown option: %s\n' "$1" >&2
		exit 1
		;;
	esac
done

tmux_get() {
	"$tmux_bin" "${socket_args[@]}" show-option -gv "$1" 2>/dev/null || true
}

tmux_msg() {
	"$tmux_bin" "${socket_args[@]}" display-message -p "$1" 2>/dev/null || true
}

config_get() {
	local key="$1"
	local value=""
	[ -n "$tmux_conf_local" ] || return 0
	[ -f "$tmux_conf_local" ] || return 0

	value="$(awk -v key="$key" '
		$1 == "set" && $2 == "-g" && $3 == key {
			sub(/^[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+/, "", $0)
			gsub(/^"/, "", $0)
			gsub(/"$/, "", $0)
			print $0
			exit
		}
	' "$tmux_conf_local" 2>/dev/null || true)"
	printf '%s' "$value"
}

value_get() {
	local key="$1"
	local value
	value="$(tmux_get "$key")"
	if [ -n "$value" ]; then
		printf '%s' "$value"
		return 0
	fi
	config_get "$key"
}

current_width() {
	local w
	w="$("$tmux_bin" "${socket_args[@]}" list-clients -F '#{client_width}' 2>/dev/null | sort -n | sed -n '1p' || true)"
	[ -n "$w" ] || w="80"
	printf '%s' "$w"
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

[ -n "$width" ] || width="$(current_width)"
[ -n "$hide_under" ] || hide_under="88"
[ -n "$small_under" ] || small_under="112"
[ -n "$medium_under" ] || medium_under="140"
[ -n "$pct_under" ] || pct_under="64"
[ -n "$user_under" ] || user_under="96"
[ -n "$date_under" ] || date_under="112"

battery_charge="$(tmux_get @battery_charge)"
battery_status="$(tmux_get @battery_status)"
battery_pct="$(tmux_get @battery_percentage)"
omt_username="$(tmux_msg '#{@omt_username}')"
omt_root="$(tmux_msg '#{@omt_root}')"
omt_hostname="$(tmux_msg '#{?@omt_hostname,#{@omt_hostname},#h}')"

bar_palette="$(value_get @omt_battery_bar_palette)"
bar_low_palette="$(value_get @omt_battery_bar_low_palette)"
bar_length="$(value_get @omt_battery_bar_length)"
bar_empty="$(value_get @omt_battery_bar_symbol_empty)"
bar_full="$(value_get @omt_battery_bar_symbol_full)"

[ -n "$bar_palette" ] || bar_palette="gradient"
[ -n "$bar_low_palette" ] || bar_low_palette="heat"
[ -n "$bar_length" ] || bar_length="8"
[ -n "$bar_empty" ] || bar_empty="◻"
[ -n "$bar_full" ] || bar_full="◼"
[ -n "$omt_hostname" ] || omt_hostname="$(hostname -s 2>/dev/null || hostname 2>/dev/null || printf '<none>')"
[ -n "$omt_username" ] || omt_username="$(id -un 2>/dev/null || printf '')"

show_pct=1
show_user=1
show_date=1
show_bar=1
render_length="$bar_length"

if [ "$width" -lt "$pct_under" ]; then
	show_pct=0
fi
if [ "$width" -lt "$user_under" ]; then
	show_user=0
fi
if [ "$width" -lt "$date_under" ]; then
	show_date=0
fi
if [ "$width" -lt "$hide_under" ]; then
	show_bar=0
elif [ "$width" -lt "$small_under" ]; then
	render_length="4"
elif [ "$width" -lt "$medium_under" ]; then
	render_length="6"
fi

render_palette="$bar_palette"
if [ -n "$battery_charge" ] && [ -n "$bar_low_palette" ] && (($(echo "$battery_charge < 0.18" | bc -l 2>/dev/null || echo 0))); then
	render_palette="$bar_low_palette"
fi

rendered_bar=""
if [ "$show_bar" -eq 1 ]; then
	rendered_bar="$(render_bar "$battery_charge" "$width" "$render_palette" "$bar_empty" "$bar_full" "$render_length")"
fi

time_now="$(date +%R)"
date_now="$(date '+%d %b')"
preview=""

if [ -n "$battery_status" ]; then
	preview="${preview}${battery_status}"
fi

if [ "$show_pct" -eq 1 ] && [ -n "$battery_pct" ]; then
	preview="${preview}${preview:+ }${battery_pct}"
fi
if [ -n "$rendered_bar" ]; then
	preview="${preview}${preview:+ }[bar:${rendered_bar}]"
fi
preview="${preview}${preview:+ }| ${time_now}"
if [ "$show_date" -eq 1 ]; then
	preview="${preview} | ${date_now}"
fi
if [ "$show_user" -eq 1 ] && [ -n "$omt_username" ]; then
	preview="${preview} | ${omt_username}${omt_root}"
fi
preview="${preview} | ${omt_hostname}"

printf 'width=%s\n' "$width"
printf 'show_battery_pct=%s\n' "$show_pct"
printf 'show_date=%s\n' "$show_date"
printf 'show_user=%s\n' "$show_user"
printf 'show_battery_bar=%s\n' "$show_bar"
printf 'battery_bar_length=%s\n' "$render_length"
printf 'battery_bar_palette=%s\n' "$render_palette"
printf 'hostname=%s\n' "${omt_hostname:-<none>}"
printf 'username=%s%s\n' "${omt_username:-}" "${omt_root:-}"
printf '\n[preview]\n%s\n' "$preview"

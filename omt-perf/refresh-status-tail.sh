#!/usr/bin/env bash
set -euo pipefail

tmux_bin="${TMUX_PROGRAM:-tmux}"
socket_args=()
if [ -n "${TMUX_SOCKET:-}" ]; then
	socket_args=(-S "$TMUX_SOCKET")
fi

width_override=""
while [ $# -gt 0 ]; do
	case "$1" in
	--width)
		width_override="${2:-}"
		shift 2
		;;
	*)
		printf 'unknown option: %s\n' "$1" >&2
		exit 1
		;;
	esac
done

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

truncate_ascii() {
	local text="$1"
	local max_len="$2"

	if [ "${#text}" -le "$max_len" ]; then
		printf '%s' "$text"
	else
		printf '%s' "${text:0:$max_len}"
	fi
}

width="$width_override"
[ -n "$width" ] || width="$(client_width_floor)"

session_name="$("$tmux_bin" "${socket_args[@]}" display-message -p '#S' 2>/dev/null || true)"
hostname_short="$("$tmux_bin" "${socket_args[@]}" display-message -p '#{?@omt_hostname,#{@omt_hostname},#h}' 2>/dev/null || true)"

[ -n "$session_name" ] || session_name="S"
[ -n "$hostname_short" ] || hostname_short="$(hostname -s 2>/dev/null || printf 'host')"

if [ "$width" -lt 64 ]; then
	tmux_set @omt_status_compact 1
	tmux_set @omt_status_compact_tail " | $(truncate_ascii "$session_name" 4)"
elif [ "$width" -lt 80 ]; then
	tmux_set @omt_status_compact 1
	tmux_set @omt_status_compact_tail " | $(truncate_ascii "$session_name" 6) | $(truncate_ascii "$hostname_short" 6)"
else
	tmux_unset @omt_status_compact
	tmux_unset @omt_status_compact_tail
fi

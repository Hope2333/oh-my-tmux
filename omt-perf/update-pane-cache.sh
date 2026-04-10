#!/usr/bin/env bash
set -euo pipefail

tmux_bin="${TMUX_PROGRAM:-tmux}"
socket_args=()
if [ -n "${TMUX_SOCKET:-}" ]; then
	socket_args=(-S "$TMUX_SOCKET")
fi

pane_id="${1:-}"
if [ -z "$pane_id" ]; then
	exit 0
fi

omt_sh="${XDG_CACHE_HOME:-$HOME/.cache}/tmux/omt.sh"
if [ ! -x "$omt_sh" ]; then
	exit 0
fi

cache_root="${XDG_CACHE_HOME:-$HOME/.cache}"
lock_dir="$cache_root/tmux/pane-cache"
mkdir -p "$lock_dir"
lock_file="$lock_dir/${pane_id#%}.lock"

stamp_file="$lock_dir/${pane_id#%}.stamp"
now_ns=$(date +%s%N)
min_interval_ns=250000000
if [ -f "$stamp_file" ]; then
	last_ns=$(cat "$stamp_file" 2>/dev/null || echo 0)
	delta_ns=$((now_ns - last_ns))
	if [ "$delta_ns" -ge 0 ] && [ "$delta_ns" -lt "$min_interval_ns" ]; then
		exit 0
	fi
fi
printf '%s' "$now_ns" >"$stamp_file"

if ! flock -n "$lock_file" -c true; then
	exit 0
fi

flock -n "$lock_file" bash -s -- "$pane_id" "$omt_sh" <<'BASH'
set -euo pipefail

tmux_bin="${TMUX_PROGRAM:-tmux}"
socket_args=()
if [ -n "${TMUX_SOCKET:-}" ]; then
	socket_args=(-S "$TMUX_SOCKET")
fi

pane_id="$1"
omt_sh="$2"

meta="$($tmux_bin "${socket_args[@]}" display-message -p -t "$pane_id" '#{pane_pid} #{b:pane_tty} #D #h')"
pane_pid="${meta%% *}"
rest="${meta#* }"
pane_tty="${rest%% *}"
rest="${rest#* }"
display_id="${rest%% *}"
short_host="${rest#* }"

username="$(sh "$omt_sh" _username "$pane_pid" "$pane_tty" false "$display_id" | tr -d '\r\n')"
hostname="$(sh "$omt_sh" _hostname "$pane_pid" "$pane_tty" false false "$short_host" "$display_id" | tr -d '\r\n')"

root_indicator=""
if [ "$username" = "root" ]; then
	root_indicator="!"
fi

"$tmux_bin" "${socket_args[@]}" set-option -pt "$pane_id" @omt_username "$username"
"$tmux_bin" "${socket_args[@]}" set-option -pt "$pane_id" @omt_hostname "$hostname"
"$tmux_bin" "${socket_args[@]}" set-option -pt "$pane_id" @omt_root "$root_indicator"
BASH

exit 0

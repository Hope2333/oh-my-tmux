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

tmux_get() {
	"$tmux_bin" "${socket_args[@]}" show-option -gv "$1" 2>/dev/null || true
}

tmux_msg() {
	"$tmux_bin" "${socket_args[@]}" display-message -p "$1" 2>/dev/null || true
}

status_right="$(tmux_get status-right)"
status_left="$(tmux_get status-left)"
socket_path="$(tmux_msg '#{socket_path}')"
server_pid="$(tmux_msg '#{pid}')"
attached_clients="$("$tmux_bin" "${socket_args[@]}" list-clients -F '#{client_name} width=#{client_width} session=#{session_name}' 2>/dev/null || true)"
hooks="$("$tmux_bin" "${socket_args[@]}" show-hooks -g 2>/dev/null | rg 'client-attached|client-resized|client-session-changed|session-created' || true)"
daemon_ps="$(ps -eo pid,ppid,stat,pcpu,pmem,comm,args | rg 'omt-perf/metrics-daemon.sh|flock -n .*/omt-metrics|bash -s' || true)"
client_width_floor="$("$tmux_bin" "${socket_args[@]}" list-clients -F '#{client_width}' 2>/dev/null | sort -n | sed -n '1p' || true)"

hotpath_state="clean"
case "$status_right" in
*"cut -c3-"*|*"sh -s _battery_status"*|*"battery-bar-worker"*)
	hotpath_state="dirty"
	;;
esac

printf 'socket_path=%s\n' "${socket_path:-<none>}"
printf 'server_pid=%s\n' "${server_pid:-<none>}"
printf 'hotpath=%s\n' "$hotpath_state"
printf 'battery_charge=%s\n' "$(tmux_get @battery_charge)"
printf 'battery_percentage=%s\n' "$(tmux_get @battery_percentage)"
printf 'battery_status=%s\n' "$(tmux_get @battery_status)"
printf 'omt_battery_bar=%s\n' "$(tmux_get @omt_battery_bar)"
printf 'omt_battery_pct=%s\n' "$(tmux_get @omt_battery_pct)"
printf 'omt_hostname=%s\n' "$(tmux_msg '#{?@omt_hostname,#{@omt_hostname},#h}')"
printf 'client_width_floor=%s\n' "${client_width_floor:-<none>}"
printf '\n[hooks]\n%s\n' "${hooks:-<none>}"
printf '\n[clients]\n%s\n' "${attached_clients:-<none>}"
printf '\n[status-left]\n%s\n' "${status_left:-<none>}"
printf '\n[status-right]\n%s\n' "${status_right:-<none>}"
printf '\n[processes]\n%s\n' "${daemon_ps:-<none>}"

#!/usr/bin/env bash
set -euo pipefail

tmux_bin="${TMUX_PROGRAM:-tmux}"
socket_args=()
if [ -n "${TMUX_SOCKET:-}" ]; then
	socket_args=(-S "$TMUX_SOCKET")
fi

tmux_conf="${TMUX_CONF:-}"
if [ -z "$tmux_conf" ]; then
	if [ -f "$HOME/.config/tmux/tmux.conf" ]; then
		tmux_conf="$HOME/.config/tmux/tmux.conf"
	elif [ -f "$HOME/.tmux.conf" ]; then
		tmux_conf="$HOME/.tmux.conf"
	else
		tmux_conf="$HOME/.config/tmux/tmux.conf"
	fi
fi

cache_root="${XDG_CACHE_HOME:-$HOME/.cache}"
cache_dir="$cache_root/tmux"
omt_sh="$cache_dir/omt.sh"

mkdir -p "$cache_dir"

refresh_cache() {
	if [ ! -f "$omt_sh" ] || [ "$tmux_conf" -nt "$omt_sh" ]; then
		tmp="$omt_sh.tmp.$$"
		cut -c3- "$tmux_conf" >"$tmp"
		chmod 700 "$tmp"
		mv "$tmp" "$omt_sh"
	fi
}

patch_status_right() {
	local sr new_sr
	sr="$($tmux_bin "${socket_args[@]}" show-option -gv status-right 2>/dev/null || true)"
	if [ -z "$sr" ]; then
		return 0
	fi

	new_sr="$(
		python3 - "$sr" "$tmux_conf" "$omt_sh" <<'PY'
import re
import sys

sr, tmux_conf, omt_sh = sys.argv[1:4]

def quote_single(s: str) -> str:
	return "'" + s.replace("'", "'\\''") + "'"

conf_pat = re.escape(tmux_conf)
pat = re.compile(r"(?P<nice>\bnice\s+)?cut\s+-c3-\s+'?" + conf_pat + r"'?\s*\|\s*sh\s+-s\s+")

def repl(m: re.Match) -> str:
	nice = m.group('nice') or ''
	return f"{nice}sh {quote_single(omt_sh)} "

sr = pat.sub(repl, sr)

sr = re.sub(
	r"#\(echo;\s*(?:nice\s+)?sh\s+'[^']+'\s+_battery_status\s+'[^']*'\s+'[^']*'\)",
	"",
	sr,
)
sr = re.sub(
	r"#\{\?@battery_percentage,\s*#\((?:nice\s+)?sh\s+'[^']+'\s+_(?:bar|hbar|vbar)\s+[^)]*\),\}",
	"",
	sr,
)
sr = re.sub(
	r"#\{\?@battery_percentage,\s*#\(sh\s+'#\{E:HOME\}/\.config/tmux/omt-perf/battery-bar-worker\.sh'\s+[^)]*\),\}",
	"",
	sr,
)

sr = re.sub(r"#\(sh\s+'[^']+'\s+_username\s+'#\{pane_pid\}'\s+'#\{b:pane_tty\}'\s+false\s+'#D'\)", "#{@omt_username}", sr)
sr = re.sub(r"#\{\?\#\{==:#\(sh\s+'[^']+'\s+_username\s+'#\{pane_pid\}'\s+'#\{b:pane_tty\}'\s+'#D'\),root\},!,\}", "#{@omt_root}", sr)
sr = re.sub(r"#\(sh\s+'[^']+'\s+_hostname\s+'#\{pane_pid\}'\s+'#\{b:pane_tty\}'\s+false\s+false\s+'#h'\s+'#D'\)", "#{@omt_hostname}", sr)

print(sr)
PY
	)"

	if [ "$new_sr" != "$sr" ]; then
		$tmux_bin "${socket_args[@]}" set-option -g status-right "$new_sr"
	fi
}

install_hooks() {
	local updater refresh refresh_bar refresh_tail
	updater="$HOME/.config/tmux/omt-perf/update-pane-cache.sh"
	refresh="$HOME/.config/tmux/omt-perf/refresh-client-panes.sh"
	refresh_bar="$HOME/.config/tmux/omt-perf/refresh-battery-bar.sh"
	refresh_tail="$HOME/.config/tmux/omt-perf/refresh-status-tail.sh"

	$tmux_bin "${socket_args[@]}" set-hook -g after-select-pane "run-shell -b '$updater \"#{pane_id}\"'"
	$tmux_bin "${socket_args[@]}" set-hook -g after-select-window "run-shell -b '$updater \"#{pane_id}\"'"
	$tmux_bin "${socket_args[@]}" set-hook -g after-new-window "run-shell -b '$updater \"#{pane_id}\"'"
	$tmux_bin "${socket_args[@]}" set-hook -g after-split-window "run-shell -b '$updater \"#{pane_id}\"'"
	$tmux_bin "${socket_args[@]}" set-hook -g client-resized "run-shell -b '$refresh_bar; $refresh_tail'"
	$tmux_bin "${socket_args[@]}" set-hook -g client-attached "run-shell -b '$refresh; $refresh_tail'"
	$tmux_bin "${socket_args[@]}" set-hook -g client-session-changed "run-shell -b '$refresh; $refresh_tail'"
	$tmux_bin "${socket_args[@]}" set-hook -g session-created "run-shell -b '$refresh; $refresh_tail'"
}

start_metrics_daemon() {
	"$HOME/.config/tmux/omt-perf/metrics-daemon.sh" >/dev/null 2>&1 &
}

stop_legacy_loops() {
	local server_pid pid ppid args
	server_pid="$($tmux_bin "${socket_args[@]}" display-message -p '#{pid}' 2>/dev/null || true)"
	[ -n "$server_pid" ] || return 0

	ps -eo pid=,ppid=,args= | while read -r pid ppid args; do
		[ "$ppid" = "$server_pid" ] || continue
		case "$args" in
		*"cut -c3-"*"_battery_info"* | *"cut -c3-"*"_uptime"* | *"cut -c3-"*"_battery_status"* | *"cut -c3-"*"_bar"*)
			kill "$pid" >/dev/null 2>&1 || true
			;;
		esac
	done
}

main() {
	refresh_cache

	sleep 0.2

	patch_status_right
	install_hooks
	start_metrics_daemon
	stop_legacy_loops
	"$HOME/.config/tmux/omt-perf/refresh-client-panes.sh"
	"$HOME/.config/tmux/omt-perf/refresh-status-tail.sh"

	$tmux_bin "${socket_args[@]}" set-option -g mouse on
}

main "$@"

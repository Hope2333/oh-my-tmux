#!/usr/bin/env bash
set -euo pipefail

tmux_bin="${TMUX_PROGRAM:-tmux}"
socket="${TMUX_SOCKET:-}"
script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [ -z "$socket" ] && [ -n "${TMUX:-}" ]; then
	socket="${TMUX%%,*}"
fi

socket_args=()
if [ -n "$socket" ]; then
	socket_args=(-S "$socket")
fi

preview_width=""
preview_preset=""
all_widths=0
json_output=0
while [ $# -gt 0 ]; do
	case "$1" in
	--width)
		preview_width="${2:-}"
		shift 2
		;;
	--preset)
		preview_preset="${2:-}"
		shift 2
		;;
	--all-widths)
		all_widths=1
		shift
		;;
	--json)
		json_output=1
		shift
		;;
	-h|--help)
		cat <<'EOF'
Usage: doctor.sh [--width N] [--preset auto|full|compact|micro] [--all-widths] [--json]
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

json_escape() {
	local value="${1:-}"
	value=${value//\\/\\\\}
	value=${value//\"/\\\"}
	value=${value//$'\n'/\\n}
	value=${value//$'\r'/\\r}
	value=${value//$'\t'/\\t}
	printf '%s' "$value"
}

render_preview() {
	local width_arg="$1"
	local preset_arg="$2"
	local args=()

	if [ -n "$width_arg" ]; then
		args+=(--width "$width_arg")
	fi
	if [ -n "$preset_arg" ]; then
		args+=(--preset "$preset_arg")
	fi

	bash "$script_dir/render-status.sh" "${args[@]}" 2>/dev/null || true
}

preview_field() {
	local output="$1"
	local key="$2"
	printf '%s\n' "$output" | awk -F= -v key="$key" '$1 == key { print $2; exit }'
}

preview_text() {
	local output="$1"
	printf '%s\n' "$output" | awk '
		/^\[preview\]$/ { getline; print; exit }
	'
}

status_right="$(tmux_get status-right)"
status_left="$(tmux_get status-left)"
socket_path="$(tmux_msg '#{socket_path}')"
server_pid="$(tmux_msg '#{pid}')"
attached_clients="$("$tmux_bin" "${socket_args[@]}" list-clients -F '#{client_name} width=#{client_width} session=#{session_name}' 2>/dev/null || true)"
hooks="$("$tmux_bin" "${socket_args[@]}" show-hooks -g 2>/dev/null | rg 'client-attached|client-resized|client-session-changed|session-created' || true)"
daemon_ps="$(ps -eo pid,ppid,stat,pcpu,pmem,comm,args | rg 'omt-perf/metrics-daemon.sh|flock -n .*/omt-metrics|bash -s' || true)"
client_width_floor="$("$tmux_bin" "${socket_args[@]}" list-clients -F '#{client_width}' 2>/dev/null | sort -n | sed -n '1p' || true)"
expanded_status_tail="$(tmux_msg '#{E:@omt_status_tail}')"
mouse_state="$(tmux_get mouse)"
theme_branch="$(tmux_get @omt_theme_branch)"

if [ -z "$preview_width" ]; then
	preview_width="$client_width_floor"
fi
if [ -z "$preview_preset" ]; then
	preview_preset="auto"
fi
preview_output="$(render_preview "$preview_width" "$preview_preset")"
preview_mode="$(preview_field "$preview_output" mode)"
preview_show_battery_pct="$(preview_field "$preview_output" show_battery_pct)"
preview_show_date="$(preview_field "$preview_output" show_date)"
preview_show_user="$(preview_field "$preview_output" show_user)"
preview_show_battery_bar="$(preview_field "$preview_output" show_battery_bar)"
preview_show_battery_status="$(preview_field "$preview_output" show_battery_status)"
preview_show_session="$(preview_field "$preview_output" show_session)"
preview_show_host="$(preview_field "$preview_output" show_host)"
preview_bar_length="$(preview_field "$preview_output" battery_bar_length)"
preview_bar_palette="$(preview_field "$preview_output" battery_bar_palette)"
preview_host_display="$(preview_field "$preview_output" host_display)"
preview_session_display="$(preview_field "$preview_output" session_display)"
preview_text_line="$(preview_text "$preview_output")"

all_widths_output=""
if [ "$all_widths" -eq 1 ]; then
	for width in 56 64 72 80 96 120; do
		all_widths_output="${all_widths_output}--- width=${width} preset=${preview_preset} ---"$'\n'
		all_widths_output="${all_widths_output}$(render_preview "$width" "$preview_preset")"$'\n'
	done
fi

hotpath_state="clean"
case "$status_right" in
*"cut -c3-"*|*"sh -s _battery_status"*|*"battery-bar-worker"*)
	hotpath_state="dirty"
	;;
esac

if [ "$json_output" -eq 1 ]; then
	printf '{\n'
	printf '  "server": {\n'
	printf '    "socket_path": "%s",\n' "$(json_escape "${socket_path:-<none>}")"
	printf '    "server_pid": "%s",\n' "$(json_escape "${server_pid:-<none>}")"
	printf '    "hotpath": "%s"\n' "$(json_escape "$hotpath_state")"
	printf '  },\n'
	printf '  "theme": {\n'
	printf '    "branch": "%s",\n' "$(json_escape "${theme_branch:-<none>}")"
	printf '    "hostname": "%s",\n' "$(json_escape "$(tmux_msg '#{?@omt_hostname,#{@omt_hostname},#h}')")"
	printf '    "mouse": "%s"\n' "$(json_escape "${mouse_state:-<none>}")"
	printf '  },\n'
	printf '  "battery": {\n'
	printf '    "charge": "%s",\n' "$(json_escape "$(tmux_get @battery_charge)")"
	printf '    "percentage": "%s",\n' "$(json_escape "$(tmux_get @battery_percentage)")"
	printf '    "status": "%s",\n' "$(json_escape "$(tmux_get @battery_status)")"
	printf '    "bar": "%s",\n' "$(json_escape "$(tmux_get @omt_battery_bar)")"
	printf '    "pct_style": "%s"\n' "$(json_escape "$(tmux_get @omt_battery_pct)")"
	printf '  },\n'
	printf '  "status": {\n'
	printf '    "compact": "%s",\n' "$(json_escape "$(tmux_get @omt_status_compact)")"
	printf '    "compact_tail": "%s",\n' "$(json_escape "$(tmux_get @omt_status_compact_tail)")"
	printf '    "tail": "%s",\n' "$(json_escape "$(tmux_get @omt_status_tail)")"
	printf '    "tail_compact_prefix": "%s",\n' "$(json_escape "$(tmux_get @omt_status_tail_compact_prefix)")"
	printf '    "tail_full_template": "%s",\n' "$(json_escape "$(tmux_get @omt_status_tail_full_template)")"
	printf '    "expanded_tail": "%s",\n' "$(json_escape "${expanded_status_tail:-<none>}")"
	printf '    "left": "%s",\n' "$(json_escape "${status_left:-<none>}")"
	printf '    "right": "%s"\n' "$(json_escape "${status_right:-<none>}")"
	printf '  },\n'
	printf '  "preview": {\n'
	printf '    "width": "%s",\n' "$(json_escape "${preview_width:-<none>}")"
	printf '    "preset": "%s",\n' "$(json_escape "${preview_preset}")"
	printf '    "mode": "%s",\n' "$(json_escape "${preview_mode:-<none>}")"
	printf '    "show_battery_pct": "%s",\n' "$(json_escape "${preview_show_battery_pct:-<none>}")"
	printf '    "show_date": "%s",\n' "$(json_escape "${preview_show_date:-<none>}")"
	printf '    "show_user": "%s",\n' "$(json_escape "${preview_show_user:-<none>}")"
	printf '    "show_battery_bar": "%s",\n' "$(json_escape "${preview_show_battery_bar:-<none>}")"
	printf '    "show_battery_status": "%s",\n' "$(json_escape "${preview_show_battery_status:-<none>}")"
	printf '    "show_session": "%s",\n' "$(json_escape "${preview_show_session:-<none>}")"
	printf '    "show_host": "%s",\n' "$(json_escape "${preview_show_host:-<none>}")"
	printf '    "battery_bar_length": "%s",\n' "$(json_escape "${preview_bar_length:-<none>}")"
	printf '    "battery_bar_palette": "%s",\n' "$(json_escape "${preview_bar_palette:-<none>}")"
	printf '    "host_display": "%s",\n' "$(json_escape "${preview_host_display:-<none>}")"
	printf '    "session_display": "%s",\n' "$(json_escape "${preview_session_display:-<none>}")"
	printf '    "text": "%s",\n' "$(json_escape "${preview_text_line:-<none>}")"
	printf '    "raw": "%s",\n' "$(json_escape "${preview_output:-<none>}")"
	printf '    "all_widths_raw": "%s"\n' "$(json_escape "${all_widths_output:-}")"
	printf '  },\n'
	printf '  "runtime": {\n'
	printf '    "client_width_floor": "%s",\n' "$(json_escape "${client_width_floor:-<none>}")"
	printf '    "hooks": "%s",\n' "$(json_escape "${hooks:-<none>}")"
	printf '    "clients": "%s",\n' "$(json_escape "${attached_clients:-<none>}")"
	printf '    "processes": "%s"\n' "$(json_escape "${daemon_ps:-<none>}")"
	printf '  }\n'
	printf '}\n'
	exit 0
fi

printf 'socket_path=%s\n' "${socket_path:-<none>}"
printf 'server_pid=%s\n' "${server_pid:-<none>}"
printf 'hotpath=%s\n' "$hotpath_state"
printf 'battery_charge=%s\n' "$(tmux_get @battery_charge)"
printf 'battery_percentage=%s\n' "$(tmux_get @battery_percentage)"
printf 'battery_status=%s\n' "$(tmux_get @battery_status)"
printf 'omt_battery_bar=%s\n' "$(tmux_get @omt_battery_bar)"
printf 'omt_battery_pct=%s\n' "$(tmux_get @omt_battery_pct)"
printf 'omt_hostname=%s\n' "$(tmux_msg '#{?@omt_hostname,#{@omt_hostname},#h}')"
printf 'omt_theme_branch=%s\n' "${theme_branch:-<none>}"
printf 'omt_status_compact=%s\n' "$(tmux_get @omt_status_compact)"
printf 'omt_status_compact_tail=%s\n' "$(tmux_get @omt_status_compact_tail)"
printf 'omt_status_tail=%s\n' "$(tmux_get @omt_status_tail)"
printf 'omt_status_tail_compact_prefix=%s\n' "$(tmux_get @omt_status_tail_compact_prefix)"
printf 'omt_status_tail_full_template=%s\n' "$(tmux_get @omt_status_tail_full_template)"
printf 'expanded_status_tail=%s\n' "${expanded_status_tail:-<none>}"
printf 'client_width_floor=%s\n' "${client_width_floor:-<none>}"
printf 'mouse=%s\n' "${mouse_state:-<none>}"
printf 'preview_width=%s\n' "${preview_width:-<none>}"
printf 'preview_preset=%s\n' "${preview_preset}"
printf '\n[hooks]\n%s\n' "${hooks:-<none>}"
printf '\n[clients]\n%s\n' "${attached_clients:-<none>}"
printf '\n[status-left]\n%s\n' "${status_left:-<none>}"
printf '\n[status-right]\n%s\n' "${status_right:-<none>}"
printf '\n[preview]\n%s\n' "${preview_output:-<none>}"
if [ "$all_widths" -eq 1 ]; then
	printf '\n[all-widths]\n%s' "${all_widths_output:-<none>}"
fi
printf '\n[processes]\n%s\n' "${daemon_ps:-<none>}"

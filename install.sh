#!/bin/bash
# Oh My Tmux - Lite Edition
# https://github.com/Hope2333/oh-my-tmux
# (‑●‑●)> dual licensed under the WTFPL v2 license and the MIT license,
#         without any warranty.
#         Copyright 2012— Gregory Pakosz (@gpakosz).
#
# ------------------------------------------------------------------------------
# 🚨 PLEASE REVIEW THE CONTENT OF THIS FILE BEFORE BLINDLY PIPING TO CURL
# ------------------------------------------------------------------------------
{
	if [ ${EUID:-$(id -u)} -eq 0 ]; then
		printf '❌ Do not execute this script as root!\n' >&2 && exit 1
	fi

	if [ -z "$BASH_VERSION" ]; then
		printf '❌ This installation script requires bash\n' >&2 && exit 1
	fi

	if ! tmux -V >/dev/null 2>&1; then
		printf '❌ tmux is not installed\n' >&2 && exit 1
	fi

	is_true() {
		case "$1" in
		true | yes | 1) return 0 ;;
		*) return 1 ;;
		esac
	}

	if ! is_true "$PERMISSIVE" && [ -n "$TMUX" ]; then
		printf '❌ tmux is currently running, please terminate the server first\n' >&2 && exit 1
	fi

	install() {
		printf '🎢 Installing Oh My Tmux - Lite Edition. Buckle up!\n' >&2
		printf '\n' >&2
		now=$(date +'%Y%d%m%S')

		# Backup existing configs
		for dir in "${XDG_CONFIG_HOME:-$HOME/.config}/tmux" "$HOME/.tmux"; do
			if [ -d "$dir" ]; then
				printf '⚠️  %s directory exists, making a backup → %s.%s\n' \
					"${dir/#"$HOME"/'~'}" "${dir/#"$HOME"/'~'}" "$now" >&2
				if ! is_true "$DRY_RUN"; then
					mv "$dir" "$dir.$now"
				fi
			fi
		done

		for conf in "$HOME/.tmux.conf" \
			"$HOME/.tmux.conf.local" \
			"${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf" \
			"${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf.local"; do
			if [ -f "$conf" ]; then
				if [ -L "$conf" ]; then
					printf '⚠️  %s symlink exists, removing → 🗑️\n' "${conf/#"$HOME"/'~'}" >&2
					if ! is_true "$DRY_RUN"; then
						rm -f "$conf"
					fi
				else
					printf '⚠️  %s file exists, making a backup → %s.%s\n' \
						"${conf/#"$HOME"/'~'}" "${conf/#"$HOME"/'~'}" "$now" >&2
					if ! is_true "$DRY_RUN"; then
						mv "$conf" "$conf.$now"
					fi
				fi
			fi
		done

		# Determine config location
		if [ -d "${XDG_CONFIG_HOME:-$HOME/.config}" ]; then
			mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/tmux"
			TMUX_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf"
		else
			TMUX_CONF="$HOME/.tmux.conf"
		fi
		TMUX_CONF_LOCAL="$TMUX_CONF.local"

		# Clone path
		OH_MY_TMUX_CLONE_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/oh-my-tmux"
		if [ -d "$OH_MY_TMUX_CLONE_PATH" ]; then
			printf '⚠️  %s exists, making a backup\n' "${OH_MY_TMUX_CLONE_PATH/#"$HOME"/'~'}" >&2
			printf '%s → %s.%s\n' "${OH_MY_TMUX_CLONE_PATH/#"$HOME"/'~'}" "${OH_MY_TMUX_CLONE_PATH/#"$HOME"/'~'}" "$now" >&2
			if ! is_true "$DRY_RUN"; then
				mv "$OH_MY_TMUX_CLONE_PATH" "$OH_MY_TMUX_CLONE_PATH.$now"
			fi
		fi

		printf '\n'
		printf '✅ Using %s\n' "${OH_MY_TMUX_CLONE_PATH/#"$HOME"/'~'}" >&2
		printf '✅ Using %s\n' "${TMUX_CONF/#"$HOME"/'~'}" >&2
		printf '✅ Using %s\n' "${TMUX_CONF_LOCAL/#"$HOME"/'~'}" >&2

		printf '\n'
		OH_MY_TMUX_REPOSITORY=${OH_MY_TMUX_REPOSITORY:-https://github.com/Hope2333/oh-my-tmux.git}
		OH_MY_TMUX_BRANCH=${OH_MY_TMUX_BRANCH:-lite}
		printf '⬇️  Cloning Oh My Tmux - Lite Edition (%s branch)...\n' "$OH_MY_TMUX_BRANCH" >&2
		if ! is_true "$DRY_RUN"; then
			mkdir -p "$(dirname "$OH_MY_TMUX_CLONE_PATH")"
			if ! git clone -q --single-branch --branch "$OH_MY_TMUX_BRANCH" "$OH_MY_TMUX_REPOSITORY" "$OH_MY_TMUX_CLONE_PATH"; then
				printf '❌ Failed to clone repository\n' >&2 && exit 1
			fi
		fi

		printf '\n'
		if is_true "$DRY_RUN" || ln -s -f "$OH_MY_TMUX_CLONE_PATH/.tmux.conf" "$TMUX_CONF"; then
			printf '✅ Symlinked %s → %s\n' "${TMUX_CONF/#"$HOME"/'~'}" "${OH_MY_TMUX_CLONE_PATH/#"$HOME"/'~'}/.tmux.conf" >&2
		fi
		if is_true "$DRY_RUN" || cp "$OH_MY_TMUX_CLONE_PATH/.tmux.conf.local" "$TMUX_CONF_LOCAL"; then
			printf '✅ Copied %s → %s\n' "${OH_MY_TMUX_CLONE_PATH/#"$HOME"/'~'}/.tmux.conf.local" "${TMUX_CONF_LOCAL/#"$HOME"/'~'}" >&2
		fi

		# Source if tmux is running
		tmux() {
			${TMUX_PROGRAM:-tmux} ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} "$@"
		}
		if ! is_true "$DRY_RUN" && [ -n "$TMUX" ]; then
			tmux set-environment -g TMUX_CONF "$TMUX_CONF"
			tmux set-environment -g TMUX_CONF_LOCAL "$TMUX_CONF_LOCAL"
			tmux source "$TMUX_CONF"
		fi

		printf '\n' >&2
		printf '🎉 Oh My Tmux - Lite Edition successfully installed 🎉\n' >&2
		printf '\n' >&2
		printf '💡 Edit %s to customize your config\n' "${TMUX_CONF_LOCAL/#"$HOME"/'~'}" >&2
		printf '💡 Press <prefix> + r to reload, <prefix> + e to edit\n' >&2
	}

	install
}

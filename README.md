# Oh My Tmux - Lite Edition

A lightweight, performance-optimized tmux configuration based on [Oh My Tmux!](https://github.com/gpakosz/.tmux).

## Features

- ⚡ **Performance Optimized**: Status caches eliminate redundant shell calls while keeping the battery bar visible
- 🎨 **Themed Status Bar**: Clean, informative status line with battery, uptime, and SSH info
- 🔧 **Easy Customization**: Override settings in `.tmux.conf.local`
- 🖱️ **Mouse Support**: Click to select panes, scroll to navigate history

## Quick Start

```bash
# Clone the lite branch
git clone -b lite --depth=1 https://github.com/Hope2333/oh-my-tmux.git ~/.local/share/tmux/oh-my-tmux

# Create symlink
mkdir -p ~/.config/tmux
ln -sf ~/.local/share/tmux/oh-my-tmux/.tmux.conf ~/.config/tmux/tmux.conf

# Start tmux
tmux
```

## Structure

```
lite branch:
├── .tmux.conf          # Main config (from gpakosz/.tmux)
├── .tmux.conf.local    # Custom overrides
└── omt-perf/           # Performance optimization scripts
    ├── apply.sh
    ├── battery-bar-worker.sh
    ├── metrics-daemon.sh
    ├── refresh-client-panes.sh
    ├── reload.sh
    ├── update-pane-cache.sh
    └── README.md
```

## Performance Optimizations

The `omt-perf/` module provides:

1. **Pane Identity Cache**: Caches username/hostname per pane instead of querying on every status refresh
2. **Battery Metrics Cache**: Caches battery status, percentage, and bar in tmux options
3. **Low-Frequency Metrics**: Battery and uptime updated every 75s instead of every status interval
4. **Legacy Loop Cleanup**: Stops the default oh-my-tmux background loops
5. **Resize Trigger**: `client-resized` refreshes the battery bar using width tiers without touching the rest of the status line
6. **Compact Tail**: Sub-80 widths switch the right tail to session-first compact labels

## Troubleshooting

Inspect runtime state:

```bash
bash ~/.config/tmux/omt-perf/doctor.sh
```

CLI entrypoint:

```bash
omtmux theme list
omtmux theme current
omtmux theme set arc-dark
omtmux theme set --force arc-dark
omtmux display mode list
omtmux display mode get
omtmux display mode set rounded
omtmux display preset list
omtmux display preset set compact
omtmux display preset save-default
omtmux display preset reset-default
omtmux display preview --width 72
omtmux doctor --width 72
omtmux doctor --all-widths
omtmux doctor --json
```

Available display modes: `square` (default), `rounded`, `diamond`.
Available display presets: `auto` (default), `full`, `compact`, `micro`.

`omtmux theme set` now refuses to switch branches when the repo worktree is dirty unless you pass `--force`.
`omtmux theme list` shows git sync state and marks the live runtime theme.
`omtmux display preset save-default` persists your preferred preset across theme switches, and `reset-default` puts it back to `auto`.
`omtmux doctor --width N` prints the live tmux state and the matching offline status preview for width `N`.
`omtmux doctor --all-widths` prints the preview matrix for `56 / 64 / 72 / 80 / 96 / 120`.
`omtmux doctor --json` emits the same runtime snapshot as JSON.

Preview a future width tier before wiring it into hooks:

```bash
bash ~/.config/tmux/omt-perf/render-status.sh --width 96
bash ~/.config/tmux/omt-perf/render-status.sh --width 72
bash ~/.config/tmux/omt-perf/render-status.sh --width 56
```

Current preview rules:

- `<80`: compact mode, keep time + session hint first
- `<64`: micro mode, keep time + shorter session hint only

## License

Dual licensed under WTFPL v2 and MIT license.
Copyright 2012— Gregory Pakosz (@gpakosz).

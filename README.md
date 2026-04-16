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

## Troubleshooting

Inspect runtime state:

```bash
bash ~/.config/tmux/omt-perf/doctor.sh
```

## License

Dual licensed under WTFPL v2 and MIT license.
Copyright 2012— Gregory Pakosz (@gpakosz).

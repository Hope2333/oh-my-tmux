# Oh My Tmux - Lite Edition

> A lightweight, performance-optimized tmux configuration based on [Oh My Tmux!](https://github.com/gpakosz/.tmux)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![License: WTFPL](https://img.shields.io/badge/License-WTFPL-blue.svg)](http://www.wtfpl.net/)

## Features

- ⚡ **Performance Optimized**: Pane caching system eliminates redundant shell calls on every status refresh
- 🎨 **Themed Status Bar**: Clean, informative status line with battery, uptime, username, and hostname
- 🔧 **Easy Customization**: Override settings in `.tmux.conf.local` without touching the main config
- 🖱️ **Mouse Support**: Click to select panes, scroll to navigate history
- 🔌 **TPM Ready**: Seamless integration with Tmux Plugin Manager
- 🐚 **SSH Aware**: Smart username/hostname display based on SSH connections

## Installation

### One-line Install

```bash
curl -fsSL "https://github.com/Hope2333/oh-my-tmux/raw/refs/heads/main/install.sh" | bash
```

### Manual Install

```bash
# 1. Clone the desired theme branch
git clone -b lite --depth=1 https://github.com/Hope2333/oh-my-tmux.git ~/.local/share/tmux/oh-my-tmux

# 2. Create symlink (XDG config style)
mkdir -p ~/.config/tmux
ln -sf ~/.local/share/tmux/oh-my-tmux/.tmux.conf ~/.config/tmux/tmux.conf

# 3. Copy local config template
cp ~/.local/share/tmux/oh-my-tmux/.tmux.conf.local ~/.config/tmux/tmux.conf.local

# 4. Start tmux
tmux
```

### Available Themes

| Branch | Preview | Description |
|---|---|---|
| `lite` | 🌑 Default Dark | Original dark theme with light blue accents |
| `arc-dark` | 🌃 Arc-Dark | Dark theme with Arc GTK colors (#383c4a bg, #5294e2 blue) |
| `arc-light` | ☀️ Arc-Light | Light theme with Arc GTK colors (#f5f6f7 bg, #5294e2 blue) |
| `arc-glass-dark` | 🪟 ArcGlass-Dark | **Transparent** dark theme, status bar only (#5294e2 blue) |
| `arc-glass-light` | 🪟 ArcGlass-Light | **Transparent** light theme, status bar only (#5294e2 blue) |

To install a specific theme, replace `-b lite` with `-b arc-dark` or `-b arc-light` in the clone command above.

### Requirements

- tmux **`>= 2.4`** running inside Linux, Mac, OpenBSD, Cygwin or WSL
- `awk`, `perl`, `sed`, `python3` (for status bar patching)
- Outside of tmux, `$TERM` should be set to `xterm-256color` or `tmux-256color`

## Configuration

### Customizing

🚨 **You should never alter the main `.tmux.conf` file.** Instead, edit `~/.config/tmux/tmux.conf.local` (or `~/.tmux.conf.local`).

Press `<prefix> + e` to open the local config in your editor. Changes take effect on next tmux start or when you reload.

### Reloading

- Press `<prefix> + r` to reload configuration
- Or run: `tmux source ~/.config/tmux/tmux.conf`

### Key Bindings

| Binding | Action |
|---|---|
| `C-b` / `C-a` | Prefix keys |
| `-` | Split window vertically |
| `_` | Split window horizontally |
| `h/j/k/l` | Navigate panes |
| `H/J/K/L` | Resize panes |
| `+` | Maximize/restore current pane |
| `m` | Toggle mouse mode |
| `r` | Reload configuration |
| `Enter` | Enter copy mode |
| `v` / `C-v` | Begin selection / rectangle toggle (copy mode) |
| `y` | Copy selection to clipboard (copy mode) |

## Performance Optimizations

This lite edition includes the `omt-perf/` module:

| Module | Description |
|---|---|
| **Pane Identity Cache** | Caches username/hostname per pane instead of querying on every status refresh |
| **Battery Bar Caching** | Pre-computed battery bar strings for different client widths |
| **Low-Frequency Metrics** | Battery and uptime updated every 75s instead of every status interval |
| **Legacy Loop Cleanup** | Stops the default oh-my-tmux background loops that run every 60s |

## TPM Plugins

To enable plugins, edit `~/.config/tmux/tmux.conf.local` and add:

```bash
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-resurrect'
# ... more plugins
```

Then:
- `<prefix> + I` - Install plugins
- `<prefix> + u` - Update plugins
- `<prefix> + Alt + u` - Uninstall plugins

## Troubleshooting

### Status bar shows empty username/hostname

Run `~/.config/tmux/omt-perf/refresh-client-panes.sh` to force refresh pane caches.

### Performance issues

1. Check for stale background processes: `ps aux | grep tmux | grep -v grep`
2. Kill legacy loops: `pkill -f "cut -c3-.*_battery_info"`
3. Re-apply optimizations: `bash ~/.config/tmux/omt-perf/apply.sh`

### Colors look wrong

Ensure your terminal supports 256 colors and `$TERM` is set correctly:
```bash
export TERM=xterm-256color
```

## License

Dual licensed under the [WTFPL v2](LICENSE.WTFPL) and the [MIT license](LICENSE.MIT), without any warranty.

Copyright 2012— Gregory Pakosz (@gpakosz).

## Credits

- Base configuration: [gpakosz/.tmux](https://github.com/gpakosz/.tmux)
- Performance optimization: Custom `omt-perf/` module

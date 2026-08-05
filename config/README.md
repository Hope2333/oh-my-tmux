# config/ — Shared configuration snippets

This directory is the **single source of truth** for configuration injected
into every theme branch. `omtconfig` (repo root) reads these snippets and
injects them into `.tmux.conf` / `.tmux.conf.local` on each branch.

| File                 | Target           | Anchor (injected before)            |
|----------------------|------------------|-------------------------------------|
| fcitx5.tmpl.snippet  | .tmux.conf       | `#   tmux set -g set-titles-string` |
| fcitx5.local.snippet | .tmux.conf.local | `# "$@"` (sentinel)                |

## fcitx5 (kmscon IME) indicator

Adds an IME state indicator (`#{@fcitx5}`) to the tmux status-right and loads
the fcitx5-tmux D-Bus plugin (`/usr/share/tmux-fcitx5/fcitx5.tmux`), giving
Chinese/Japanese input inside kmscon.

Override per-install in `tmux.conf.local` (uncomment):

```tmux
set -g tmux_conf_theme_fcitx5_mode "kmscon-only"  # none | kmscon-only | force
set -g tmux_conf_theme_fcitx5_position "left"     # left | center | right
```

- `none` — never inject / never load plugin
- `kmscon-only` (default) — inject only when `$TERM` contains `kmscon`
- `force` — always inject (e.g. desktop terminals with a running fcitx5)

## Future extension

Add a new `*.tmpl.snippet` / `*.local.snippet` pair here, extend `omtconfig`
with a new marker, and run `omtconfig sync --all --commit`.

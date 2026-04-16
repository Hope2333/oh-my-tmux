# tmux Performance Plan

## Goal

Keep multi-window and multi-client tmux use responsive by removing per-refresh
status shell work. The status line should render from cached tmux options, while
`omt-perf` updates those options at low frequency or on pane/client events.

## Current Lane

1. Remove `cut -c3- ... | sh -s` from `status-right`.
2. Keep username, hostname, root, battery status, battery percentage, and
   battery bar in `@omt_*` cache options.
3. Run expensive battery and uptime probes only from `metrics-daemon.sh`.
4. Recompute responsive status tiers from the narrowest attached client width.
5. Refresh pane identity from hooks on pane/window/client changes.
6. Verify every theme branch with an isolated tmux server before pushing.

## Verification Gates

- `tmux source-file .tmux.conf` succeeds in an isolated server.
- `tmux show-option -gv status-right` contains no `cut -c3-`.
- `tmux show-option -gv status-right` contains no `sh -s _battery_status`.
- `tmux show-option -gv status-right` contains no `sh ... _bar`.
- `tmux show-option -gv @omt_battery_bar` is non-empty when width allows a battery bar.
- `tmux show-option -gv @omt_battery_bar` is empty below the hide threshold.
- `bash -n omt-perf/*.sh` passes.

## Branch Policy

Apply the same status-cache contract to every maintained branch:

- `lite`
- `arc-dark`
- `arc-light`
- `arc-glass-dark`
- `arc-glass-light`
- `main` documents and installs the optimized branches.

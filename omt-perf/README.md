# omt-perf docs index

Detailed language-separated docs live in the project workspace:

- 中文：`/home/miao/.sisyphus/tmux-perf-20260215-101224/README.zh-CN.md`
- English: `/home/miao/.sisyphus/tmux-perf-20260215-101224/README.en.md`

If you only need script responsibilities quickly:

- `apply.sh`: bootstrap + patch + hooks + daemon + mouse
- `doctor.sh`: runtime inspection for socket, hooks, cached battery data, and hot paths
- `reload.sh`: reload and re-apply
- `update-pane-cache.sh`: ssh-aware identity cache (pane-scoped)
- `refresh-client-panes.sh`: refresh active panes for clients
- `metrics-daemon.sh`: low-frequency metrics + cached battery bar
- `battery-bar-worker.sh`: legacy cache-first battery bar worker for local overrides

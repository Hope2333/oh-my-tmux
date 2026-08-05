# Oh My Tmux

一个基于 Oh My Tmux! (https://github.com/gpakosz/.tmux) 的、带管理工具与 fcitx5 输入法集成的 tmux 配置仓库。

主题通过 git 分支切换实现，管理中枢(main)持有全部主题分支与唯一配置事实源(config/)。

## 分支结构

- main: 仓库中枢。持有 omtconfig 管理工具、config/ 事实源(snippet)与多语言文档。
  - config/fcitx5.tmpl.snippet -- 注入到 .tmux.conf 的模板段
  - config/fcitx5.local.snippet -- 注入到 .tmux.conf.local 的注释/配置段
- 主题分支: arc-dark, dark, light, arc-light, arc-glass-dark, arc-glass-light, lite。
  - 每个主题分支持各自的 .tmux.conf + .tmux.conf.local 与 omtconfig 工具副本。

## 安装

git clone https://github.com/Hope2333/oh-my-tmux.git ~/.local/share/tmux/oh-my-tmux
git -C ~/.local/share/tmux/oh-my-tmux checkout arc-dark   # 选一个主题
mkdir -p ~/.config/tmux
ln -sf ~/.local/share/tmux/oh-my-tmux/.tmux.conf ~/.config/tmux/tmux.conf
cp ~/.local/share/tmux/oh-my-tmux/.tmux.conf.local ~/.config/tmux/tmux.conf.local
tmux

## omtconfig 管理工具

omtconfig 是幂等的配置同步工具，以 main 分支的 config/ 为唯一事实源：

omtconfig list
omtconfig sync --all                # 将 config/ 中的 snippet 同步到全部主题分支(暂存)
omtconfig sync --all --commit       # 同步并提交
omtconfig sync                      # 仅同步当前分支
omtconfig doctor                    # 体检: 事实源/注入/冗余分支检查
omtconfig --help

## fcitx5 输入法集成 (kmscon IME)

状态栏内联输入法指示器，用于 kmscon 等无桌面会话的终端 (配合 fcitx5-tmux)。

位置: 默认在 power/prefix 指示器**左边**，center/right 可选。用原生 tmux user-option #{@fcitx5} 渲染，
由 fcitx5-tmux 代理更新；运行时由 omt-perf/apply.sh 的 patch_status_right 保留该插值不被覆盖。

### 配置项 (.tmux.conf.local)

# 模式 (默认 kmscon-only):
#   none          -- 禁用，从不加载 fcitx5 插件
#   kmscon-only   -- 仅当 $TERM 含 "kmscon" 时启用 (默认)
#   force         -- 任何终端都启用
tmux_conf_theme_fcitx5_mode="kmscon-only"

# 指示器位置 (默认 left):
#   left   -- power/prefix 指示器左侧 (推荐)
#   center -- prefix 与 power 之间
#   right  -- 最右侧 (时间之后)
tmux_conf_theme_fcitx5_position="left"

# 未来扩展预留: 额外状态段 (任选非空即生效)
# tmux_conf_theme_status_left_extra=""
# tmux_conf_theme_status_right_extra=""

### 事实源 (config/)

以 main 分支的 config/fcitx5.tmpl.snippet 与 config/fcitx5.local.snippet 为唯一来源。
修改事实源后运行 omtconfig sync --all --commit 即可注入到全部主题分支。

## omtmux 命令

- omtmux theme list / current / set [--force] <dark|light|arc-dark|...> -- 主题切换 (git 分支)
- omtmux display mode list / get / set <square|rounded|diamond> -- 电池/分隔符号样式
- omtmux display preset list / get / set <auto|full|compact|micro> -- 状态栏宽度档位
- omtmux display preset save-default / reset-default -- 跨主题保留偏好
- omtmux doctor [--width N] [--all-widths] [--json] -- 运行时体检
- omtmux verify [--json] [--matrix] -- 断言行检查，--matrix 遍历全部主题分支

## 性能优化 (omt-perf)

- 窗格身份缓存 (username/hostname) -- 避免每次状态刷新重复查询
- 电池指标缓存 (状态/百分比/条) 到 tmux options
- 低频指标: 电池与 uptime 每 75s 更新
- 停止默认后台循环; client-resized 触发电池条宽度档刷新
- 亚 80 列切紧凑尾部，亚 64 列切 micro

## 验证

omtconfig doctor
omtmux verify --matrix
omtmux doctor --all-widths

## 多语言文档

- 简体中文 (README.zh_Sim.md)
- 繁體中文 (README.zh_Tra.md)
- 日本語 (README.ja.md)

## License

Dual licensed under WTFPL v2 and MIT license. Copyright 2012- Gregory Pakosz (@gpakosz).

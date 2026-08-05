# Oh My Tmux

一個基於 Oh My Tmux! (https://github.com/gpakosz/.tmux) 的、帶管理工具與 fcitx5 輸入法整合的 tmux 設定倉庫。

主題透過 git 分支切換實現，管理中樞(main)持有全部主題分支與唯一設定事實來源(config/)。

## 分支結構

- main: 倉庫中樞。持有 omtconfig 管理工具、config/ 事實來源(snippet)與多語言文件。
  - config/fcitx5.tmpl.snippet -- 注入到 .tmux.conf 的模板段
  - config/fcitx5.local.snippet -- 注入到 .tmux.conf.local 的註解/設定段
- 主題分支: arc-dark, dark, light, arc-light, arc-glass-dark, arc-glass-light, lite。
  - 每個主題分支持有各自的 .tmux.conf + .tmux.conf.local 與 omtconfig 工具副本。

## 安裝

git clone https://github.com/Hope2333/oh-my-tmux.git ~/.local/share/tmux/oh-my-tmux
git -C ~/.local/share/tmux/oh-my-tmux checkout arc-dark   # 選一個主題
mkdir -p ~/.config/tmux
ln -sf ~/.local/share/tmux/oh-my-tmux/.tmux.conf ~/.config/tmux/tmux.conf
cp ~/.local/share/tmux/oh-my-tmux/.tmux.conf.local ~/.config/tmux/tmux.conf.local
tmux

## omtconfig 管理工具

omtconfig 是冪等的設定同步工具，以 main 分支的 config/ 為唯一事實來源：

omtconfig list
omtconfig sync --all                # 將 config/ 中的 snippet 同步到全部主題分支(暫存)
omtconfig sync --all --commit       # 同步並提交
omtconfig sync                      # 僅同步當前分支
omtconfig doctor                    # 體檢: 事實來源/注入/冗餘分支檢查
omtconfig --help

## fcitx5 輸入法整合 (kmscon IME)

狀態列內聯輸入法指示器，用於 kmscon 等無桌面工作階段的終端 (配合 fcitx5-tmux)。

位置: 預設在 power/prefix 指示器**左邊**，center/right 可選。用原生 tmux user-option #{@fcitx5} 渲染，
由 fcitx5-tmux 代理更新；執行時由 omt-perf/apply.sh 的 patch_status_right 保留該插值不被覆寫。

### 設定項 (.tmux.conf.local)

# 模式 (預設 kmscon-only):
#   none          -- 停用，永不載入 fcitx5 外掛
#   kmscon-only   -- 僅當 $TERM 含 "kmscon" 時啟用 (預設)
#   force         -- 任何終端都啟用
tmux_conf_theme_fcitx5_mode="kmscon-only"

# 指示器位置 (預設 left):
#   left   -- power/prefix 指示器左側 (建議)
#   center -- prefix 與 power 之間
#   right  -- 最右側 (時間之後)
tmux_conf_theme_fcitx5_position="left"

# 未來擴充預留: 額外狀態段 (任一非空即生效)
# tmux_conf_theme_status_left_extra=""
# tmux_conf_theme_status_right_extra=""

### 事實來源 (config/)

以 main 分支的 config/fcitx5.tmpl.snippet 與 config/fcitx5.local.snippet 為唯一來源。
修改事實來源後執行 omtconfig sync --all --commit 即可注入到全部主題分支。

## omtmux 指令

- omtmux theme list / current / set [--force] <dark|light|arc-dark|...> -- 主題切換 (git 分支)
- omtmux display mode list / get / set <square|rounded|diamond> -- 電池/分隔符號樣式
- omtmux display preset list / get / set <auto|full|compact|micro> -- 狀態列寬度檔位
- omtmux display preset save-default / reset-default -- 跨主題保留偏好
- omtmux doctor [--width N] [--all-widths] [--json] -- 執行時體檢
- omtmux verify [--json] [--matrix] -- 斷言行檢查，--matrix 遍歷全部主題分支

## 效能最佳化 (omt-perf)

- 窗格身分快取 (username/hostname) -- 避免每次狀態更新重複查詢
- 電池指標快取 (狀態/百分比/條) 到 tmux options
- 低頻指標: 電池與 uptime 每 75s 更新
- 停止預設背景迴圈; client-resized 觸發電池條寬度檔更新
- 小於 80 欄切緊湊尾部，小於 64 欄切 micro

## 驗證

omtconfig doctor
omtmux verify --matrix
omtmux doctor --all-widths

## 多語言文件

- English (README.md)
- 简体中文 (README.zh_Sim.md)
- 日本語 (README.ja.md)

## License

Dual licensed under WTFPL v2 and MIT license. Copyright 2012- Gregory Pakosz (@gpakosz).

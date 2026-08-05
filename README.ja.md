# Oh My Tmux

Oh My Tmux! (https://github.com/gpakosz/.tmux) をベースに、管理ツールと fcitx5 入力メソッド統合を備えた tmux 設定リポジトリ。

テーマは git ブランチ切り替えで実現。管理ハブ(main)が全テーマブランチと唯一の設定ソース(config/)を保持します。

## ブランチ構成

- main: リポジトリのハブ。omtconfig 管理ツール、config/ ソース(snippet)、多言語ドキュメントを保持。
  - config/fcitx5.tmpl.snippet -- .tmux.conf へ注入するテンプレート断片
  - config/fcitx5.local.snippet -- .tmux.conf.local へ注入するコメント/設定断片
- テーマブランチ: arc-dark, dark, light, arc-light, arc-glass-dark, arc-glass-light, lite。
  - 各テーマブランチは独自の .tmux.conf + .tmux.conf.local と omtconfig ツールのコピーを保持。

## インストール

git clone https://github.com/Hope2333/oh-my-tmux.git ~/.local/share/tmux/oh-my-tmux
git -C ~/.local/share/tmux/oh-my-tmux checkout arc-dark   # テーマを選択
mkdir -p ~/.config/tmux
ln -sf ~/.local/share/tmux/oh-my-tmux/.tmux.conf ~/.config/tmux/tmux.conf
cp ~/.local/share/tmux/oh-my-tmux/.tmux.conf.local ~/.config/tmux/tmux.conf.local
tmux

## omtconfig 管理ツール

omtconfig は冪等な設定同期ツール。main ブランチの config/ を唯一のソースとします：

omtconfig list
omtconfig sync --all                # config/ の snippet を全テーマブランチへ同期(ステージ)
omtconfig sync --all --commit       # 同期してコミット
omtconfig sync                      # 現在のブランチのみ同期
omtconfig doctor                    # 診断: ソース/注入/冗長ブランチ検査
omtconfig --help

## fcitx5 入力メソッド統合 (kmscon IME)

ステータスバー内インライン入力メソッドインジケータ。kmscon などデスクトップセッションのない端末向け (fcitx5-tmux と併用)。

位置: デフォルトは power/prefix インジケータの**左**。center/right も選択可。ネイティブ tmux user-option #{@fcitx5} で描画され、
fcitx5-tmux エージェントが更新。実行時は omt-perf/apply.sh の patch_status_right がこの補間を上書きから保護します。

### 設定項目 (.tmux.conf.local)

# モード (デフォルト kmscon-only):
#   none          -- 無効、fcitx5 プラグインを一切読み込まない
#   kmscon-only   -- $TERM が "kmscon" を含む場合のみ有効 (デフォルト)
#   force         -- どの端末でも有効
tmux_conf_theme_fcitx5_mode="kmscon-only"

# インジケータ位置 (デフォルト left):
#   left   -- power/prefix インジケータの左 (推奨)
#   center -- prefix と power の間
#   right  -- 右端 (時刻の後)
tmux_conf_theme_fcitx5_position="left"

# 将来の拡張用: 追加ステータス断片 (空でなければ有効)
# tmux_conf_theme_status_left_extra=""
# tmux_conf_theme_status_right_extra=""

### 設定ソース (config/)

main ブランチの config/fcitx5.tmpl.snippet と config/fcitx5.local.snippet が唯一のソース。
ソースを編集後、omtconfig sync --all --commit を実行すると全テーマブランチへ注入されます。

## omtmux コマンド

- omtmux theme list / current / set [--force] <dark|light|arc-dark|...> -- テーマ切替 (git ブランチ)
- omtmux display mode list / get / set <square|rounded|diamond> -- バッテリー/セパレータ記号スタイル
- omtmux display preset list / get / set <auto|full|compact|micro> -- ステータスバー幅プリセット
- omtmux display preset save-default / reset-default -- テーマ横断で設定を保持
- omtmux doctor [--width N] [--all-widths] [--json] -- 実行時診断
- omtmux verify [--json] [--matrix] -- アサーションチェック、--matrix は全テーマブランチを走査

## パフォーマンス最適化 (omt-perf)

- ペイン ID キャッシュ (username/hostname) -- ステータス更新ごとの再クエリを回避
- バッテリー指標キャッシュ (状態/パーセント/バー) を tmux options へ
- 低頻度指標: バッテリーと uptime は 75s ごとに更新
- デフォルトのバックグラウンドループを停止; client-resized でバッテリーバーの幅段を更新
- 80 列未満でコンパクトテール、64 列未満で micro

## 検証

omtconfig doctor
omtmux verify --matrix
omtmux doctor --all-widths

## 多言語ドキュメント

- English (README.md)
- 简体中文 (README.zh_Sim.md)
- 繁體中文 (README.zh_Tra.md)

## License

Dual licensed under WTFPL v2 and MIT license. Copyright 2012- Gregory Pakosz (@gpakosz).

# make-ubuntu-setup

新しい Ubuntu マシンに対して、開発に必要なアプリ・ツール・日本語入力 (Fcitx5 + Mozc) を一発でセットアップするためのスクリプト群です。

- 対象 OS: **Ubuntu 22.04 以上**
- 実行は全自動・非対話。最初に sudo パスワードを 1 回だけ要求します。

## インストールされるもの

### apt パッケージ (開発ツール)

`build-essential cmake git curl wget unzip ca-certificates gnupg lsb-release tmux byobu htop ncdu tree jq python3-pip ufw software-properties-common openssh-server net-tools terminator ffmpeg`

### アプリ

- Google Chrome (apt 公式リポジトリ)
- Visual Studio Code (Microsoft apt リポジトリ)
- Slack (snap)

### Python / パッケージマネージャ

- [uv](https://github.com/astral-sh/uv) (公式インストーラ)
- [pixi](https://pixi.sh) (公式インストーラ)

### 日本語入力

- Fcitx5 + Mozc
- `変換` キーで Mozc を ON、`無変換` キーで OFF (macOS の `かな` / `英数` 相当)

## 使い方

```bash
git clone <this-repo-url> ~/make-ubuntu-setup
cd ~/make-ubuntu-setup
bash install.sh
```

完了後は **必ずログアウト → ログイン (または再起動)** してください。
日本語入力 (Fcitx5) の有効化と、`uv` / `pixi` の PATH 反映に必要です。

### 一部だけスキップしたい場合

`--skip` でプレフィックス (`30`) または basename (`30-slack`) を指定します。複数指定可。

```bash
# Slack を入れずに実行
bash install.sh --skip 30-slack

# Slack と Chrome を抜く
bash install.sh --skip 30 --skip 10
```

### 個別スクリプトだけ実行したい場合

`scripts/` 配下のスクリプトはそれぞれ単独でも動きます。

```bash
bash scripts/60-fcitx5-mozc.sh
```

## 冪等性について

各スクリプトは既にインストール済みの項目をスキップします。同じマシンで再実行しても安全です。
ただし以下は**既存ファイルがあれば上書きしません**:

- `~/.config/fcitx5/profile`
- `~/.config/fcitx5/config`
- `/etc/environment.d/99-fcitx5.conf`

既存の Fcitx5 カスタマイズを尊重するためです。リセットしたい場合は手動で削除してから再実行してください。

## ディレクトリ構成

```text
.
├── install.sh                  # トップレベル orchestrator
├── scripts/
│   ├── lib.sh                  # 共通ヘルパ
│   ├── 00-apt-base.sh          # apt 基本パッケージ
│   ├── 10-google-chrome.sh     # Chrome
│   ├── 20-vscode.sh            # VSCode
│   ├── 30-slack.sh             # Slack (snap)
│   ├── 40-uv.sh                # uv
│   ├── 50-pixi.sh              # pixi
│   └── 60-fcitx5-mozc.sh       # Fcitx5 + Mozc
└── config/
    └── fcitx5/
        ├── profile             # mozc を default IM に
        └── config              # Henkan/Muhenkan キー割り当て (global hotkey)
```

## トラブルシュート

- **Chrome や VSCode が起動しない**: 一度ログアウト/ログインしてください。
- **変換 / 無変換キーが効かない**: ログアウト/ログイン後、`fcitx5` プロセスが起動しているか `pgrep fcitx5` で確認してください。起動していなければ `fcitx5 -d` で起動します。
- **Wayland セッションで IME が出ない**: `/etc/environment.d/99-fcitx5.conf` が読み込まれるよう、必ず再ログインしてください。GNOME on Wayland では追加で `org.freedesktop.IBus` 互換のため一部アプリで再起動が必要な場合があります。

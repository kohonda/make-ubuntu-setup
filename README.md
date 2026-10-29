# make-ubuntu-setup

新しい Ubuntu マシンに対して、開発に必要なアプリ・ツール・日本語入力 (Fcitx5 + Mozc) を一発でセットアップするためのスクリプト群です。

- 対象 OS: **Ubuntu 22.04 / 24.04 以上**
- 実行は全自動・非対話。最初に sudo パスワードを 1 回だけ要求します (実行中はバックグラウンドで sudo の認証を延長します)。

## インストールされるもの

### apt パッケージ (開発ツール)

`build-essential cmake git curl wget unzip ca-certificates gnupg lsb-release tmux byobu htop ncdu tree jq python3-pip ufw software-properties-common openssh-server net-tools terminator ffmpeg`

CLI 基本ツール: `ripgrep fd-find fzf git-lfs vim xclip python3-venv pkg-config ninja-build`

### アプリ (公式 .deb)

- Google Chrome (amd64 のみ。arm64 版は存在しないためスキップ)
- Visual Studio Code (amd64 / arm64)
- Slack (amd64 のみ)

各パッケージは自分で apt ソース (`google-chrome.sources` / `vscode.sources` など) を登録するので、以降は `apt upgrade` で更新されます。

### 開発ツール

- [GitHub CLI (gh)](https://cli.github.com/) (公式 apt リポジトリ)
- [Node.js](https://github.com/nodesource/distributions) LTS (NodeSource apt リポジトリ。`node` が既に PATH にあればスキップ)
- [Docker Engine](https://docs.docker.com/engine/install/ubuntu/) + Buildx + Compose plugin (Docker 公式 apt リポジトリ)
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) (`nvidia-smi` が動く GPU 機のみ。ドライバ自体は入れません)
- [Claude Code](https://docs.claude.com/en/docs/claude-code/setup) (公式インストーラ)
- [Codex CLI](https://github.com/openai/codex) (公式 standalone インストーラ)

### Python / パッケージマネージャ

- [uv](https://github.com/astral-sh/uv) (公式インストーラ)
- [pixi](https://pixi.sh) (公式インストーラ)

### 日本語入力

- Fcitx5 + Mozc (gtk3 / gtk4 / qt5 / qt6 の frontend も明示的に入れます。qt6 は 24.04 以降のみ)
- 既定は **JIS 配列** (`jp`)。`変換` キーで日本語 (Mozc)、`無変換` キーで英語 (直接入力)。どちらもトグルではなく、押すと常に決まった方の入力になります (macOS の `かな` / `英数` 相当)
- GNOME の入力ソースは `[('xkb', '<layout>')]` だけにします (ibus エンジンが残っていると ibus も起動して競合するため)。ibus パッケージ自体は削除しません

US 配列のキーボードを使う場合は `FCITX5_LAYOUT` で指定します。

```bash
FCITX5_LAYOUT=us bash install.sh
```

## 使い方

```bash
git clone <this-repo-url> ~/make-ubuntu-setup
cd ~/make-ubuntu-setup
bash install.sh
```

完了後は **必ずログアウト → ログイン (または再起動)** してください。
日本語入力 (Fcitx5) の有効化、`docker` グループへの追加、`uv` / `pixi` / `claude` / `codex` の PATH 反映に必要です。

### 一部だけスキップしたい場合

`--skip` でプレフィックス (`30`) または basename (`30-slack`) を指定します。複数指定可。

```bash
# Slack を入れずに実行
bash install.sh --skip 30-slack

# Docker と NVIDIA Container Toolkit を抜く
bash install.sh --skip 80 --skip 85
```

### 個別スクリプトだけ実行したい場合

`scripts/` 配下のスクリプトはそれぞれ単独でも動きます。

```bash
bash scripts/60-fcitx5-mozc.sh
```

## 冪等性について

各スクリプトは既にインストール済みの項目をスキップします。同じマシンで再実行しても安全です。

Fcitx5 関連の以下のファイルは**毎回書き直します**。内容が変わる場合だけ、既存のファイルを `*.bak` に退避してから上書きします (内容が同じなら何もしません)。

- `~/.config/fcitx5/profile`
- `~/.config/fcitx5/config`
- `/etc/environment.d/99-fcitx5.conf`

書き込みの前に `fcitx5` を停止します (起動中の fcitx5 は終了時に設定を書き戻し、書いた内容を上書きしてしまうため)。

旧版のスクリプトが書いた `google-chrome.list` / `vscode.list` / `/usr/share/keyrings/packages.microsoft.gpg` は、旧版が書いた内容と完全に一致する場合だけ削除します。

## 注意

### docker グループ

`80-docker.sh` は実行ユーザを `docker` グループに追加します。反映には再ログインが必要です。`docker` グループは実質 root 権限と同等なので、共用マシンでは注意してください。

### snap 版 Slack からの移行

snap 版 Slack は confinement のため fcitx5 のモジュールを読めず、日本語入力ができません。`30-slack.sh` は .deb 版を入れますが、snap 版は自動では削除しません。snap 版が入っていると警告が出るので、.deb 版の動作を確認してから削除してください。

```bash
sudo snap remove slack
```

## ディレクトリ構成

```text
.
├── install.sh                       # トップレベル orchestrator
├── scripts/
│   ├── lib.sh                       # 共通ヘルパ
│   ├── 00-apt-base.sh               # apt 基本パッケージ
│   ├── 10-google-chrome.sh          # Chrome (.deb)
│   ├── 20-vscode.sh                 # VSCode (.deb)
│   ├── 30-slack.sh                  # Slack (.deb)
│   ├── 40-uv.sh                     # uv
│   ├── 50-pixi.sh                   # pixi
│   ├── 60-fcitx5-mozc.sh            # Fcitx5 + Mozc
│   ├── 70-gh.sh                     # GitHub CLI
│   ├── 75-nodejs.sh                 # Node.js LTS
│   ├── 80-docker.sh                 # Docker Engine + Compose
│   ├── 85-nvidia-container-toolkit.sh  # NVIDIA Container Toolkit (GPU 機のみ)
│   ├── 90-claude-code.sh            # Claude Code
│   └── 95-codex.sh                  # Codex CLI
└── config/
    └── fcitx5/
        ├── profile.template         # keyboard-<layout> + mozc。@LAYOUT@ を FCITX5_LAYOUT で置換
        └── config                   # Henkan/Muhenkan キー割り当て (global hotkey)
```

## トラブルシュート

- **旧版で `apt-get update` が "Conflicting values set for option Signed-By" で失敗する**: 旧版の `vscode.list` が原因です。`00-apt-base.sh` の `apt-get update` で止まるので、先に `bash scripts/20-vscode.sh` を実行してから `bash install.sh` を再実行してください。
- **Chrome や VSCode が起動しない**: 一度ログアウト/ログインしてください。
- **変換 / 無変換キーが効かない**: ログアウト/ログイン後、`fcitx5` プロセスが起動しているか `pgrep fcitx5` で確認してください。起動していなければ `fcitx5 -d` で起動します。
- **ibus と fcitx5 が両方動いている**: デスクトップにログインした状態で `bash scripts/60-fcitx5-mozc.sh` を再実行してください (GNOME の入力ソースの設定にはデスクトップセッションが必要です)。
- **Wayland セッションで IME が出ない**: `/etc/environment.d/99-fcitx5.conf` が読み込まれるよう、必ず再ログインしてください。

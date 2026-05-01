# ubuntuの一発セットアップ

新しいubuntu環境を一発でセットアップするために、dotfilesを作成して、他の環境に簡単に簡単に移行できるようにしたいです。
基本的にubuntu 22.04以上を想定しています.
また、使い方もreadmeに記載してください。

## 標準でインストールするもの

- google chrome: https://support.google.com/chrome/answer/95346?hl=en&co=GENIE.Platform%3DDesktop
- vscode: https://code.visualstudio.com/docs/setup/linux
- slack: https://slack.com/help/articles/212924728-Download-Slack-for-Linux--beta-
- uv
- pixi
- 以下のような、開発に必要そうなライブラリ
  - build-essential cmake git curl wget unzip ca-certificates gnupg lsb-release \
    tmux byobu htop ncdu tree jq \
    python3-pip ufw software-properties-common \
    openssh-server net-tools terminator ffmpeg

## 設定

-  Fcitx5 と Mozc をインストールして、日本語入力を可能にする。
-  日本語入力の切り替えは「変換」と「無変換」キーで行う。(macの「英数」と「かな」キーに相当)

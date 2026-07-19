#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROFILE_SLUG="linux-daily"
PROFILE_TITLE="Linux Install Kit 日常版"
PROFILE_DESCRIPTION="本腳本會安裝 Ubuntu / Zorin 的一般日常使用環境。"

apt_prereq_array=("curl" "git" "ca-certificates" "gnupg" "lsb-release" "software-properties-common" "nodejs" "npm" "bc" "vim" "build-essential" "pkg-config" "libssl-dev")
apt_array=("zsh" "bash-completion" "jq" "shellcheck" "wget" "telnet" "tree" "fzf" "pv" "dialog" "webp" "wireguard" "openvpn" "network-manager-openvpn-gnome" "ffmpeg" "p7zip-full" "poppler-utils" "fd-find" "ripgrep" "zoxide" "imagemagick" "chafa" "xclip" "unzip" "fontconfig")
snap_array=("yq" "drawio")
snap_classic_array=("code")
manual_install_array=("google-chrome")
unsupported_app_array=("iterm2" "raycast" "openvpn-connect")

ENABLE_ENGINEER_FEATURES=false
ENABLE_AUTOJUMP=false
ENABLE_SLIDEV=false
ENABLE_HELM_DIFF=false

source "$SCRIPT_DIR/install-linux-common.sh"
run_linux_install

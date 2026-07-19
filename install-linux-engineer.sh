#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROFILE_SLUG="linux-engineer"
PROFILE_TITLE="Linux Install Kit 工程師版"
PROFILE_DESCRIPTION="本腳本會安裝 Ubuntu / Zorin 的工程師工作環境，包含日常工具與 K8s / Cloud 類工具。"

apt_prereq_array=("curl" "git" "ca-certificates" "gnupg" "lsb-release" "software-properties-common" "nodejs" "npm" "bc" "vim" "build-essential" "pkg-config" "libssl-dev")
apt_array=("zsh" "bash-completion" "wget" "curl" "git" "jq" "tree" "telnet" "ca-certificates" "gnupg" "lsb-release" "software-properties-common" "fzf" "dialog" "bc" "vim" "ipcalc" "shellcheck" "hugo" "golang-go" "nodejs" "npm" "autojump" "kubectx" "wireguard" "openvpn" "network-manager-openvpn-gnome" "ffmpeg" "p7zip-full" "poppler-utils" "fd-find" "ripgrep" "zoxide" "imagemagick" "chafa" "xclip" "unzip" "fontconfig")
snap_array=("yq" "drawio")
snap_classic_array=("kubectl" "helm" "aws-cli" "code" "docker")
manual_install_array=("k9s" "kustomize" "terragrunt" "terraform" "gcloud" "google-chrome")
unsupported_app_array=("iterm2" "raycast" "openvpn-connect")

ENABLE_ENGINEER_FEATURES=true
ENABLE_AUTOJUMP=true
ENABLE_SLIDEV=true
ENABLE_HELM_DIFF=true

source "$SCRIPT_DIR/install-linux-common.sh"
run_linux_install

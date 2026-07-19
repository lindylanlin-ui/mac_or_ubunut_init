#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROFILE_SLUG="mac-daily"
PROFILE_TITLE="mac-install 日常版"
PROFILE_DESCRIPTION="本腳本會安裝一般使用者日常使用的 mac 環境與 shell 設定。"

brew_tap_array=()
brew_array=("zsh" "bash-completion" "jq" "shellcheck" "wget" "telnet" "tree" "fzf" "pv" "dialog" "yq" "webp" "autojump" "yazi" "ffmpeg" "sevenzip" "poppler" "fd" "ripgrep" "zoxide" "resvg" "imagemagick")
brew_cask=("google-chrome" "iterm2" "visual-studio-code" "raycast" "openvpn-connect" "drawio" "font-meslo-lg-nerd-font")

ENABLE_OH_MY_ZSH=true
ENABLE_FZF_TAB=true
ENABLE_ZSH_AUTOSUGGESTIONS=true
ENABLE_ZSH_SYNTAX_HIGHLIGHTING=true
ENABLE_AUTOJUMP=true
ENABLE_PS1=true
ENABLE_VIMRC=true
ENABLE_ITERM2_PROFILE=true

ENABLE_KUBECOLOR=false
ENABLE_SLIDEV=false
ENABLE_HELM_DIFF=false
ENABLE_GKE_GCLOUD_AUTH_PLUGIN=false
ENABLE_TERRAFORM_AUTOCOMPLETE=false
ENABLE_VAULT_AUTOCOMPLETE=false
ENABLE_AWS_AUTOCOMPLETE=false
ENABLE_K8S_ALIASES=false

source "$SCRIPT_DIR/install-mac-common.sh"
run_mac_install

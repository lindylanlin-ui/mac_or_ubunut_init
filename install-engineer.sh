#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROFILE_SLUG="mac-engineer"
PROFILE_TITLE="mac-install 工程師版"
PROFILE_DESCRIPTION="本腳本會安裝工程師工作用的 mac 環境，包含日常 shell 設定與 Kubernetes/Cloud 工具。"

brew_tap_array=("hashicorp/tap" "k8sgpt-ai/k8sgpt" "common-fate/granted")
brew_array=("zsh" "bash-completion" "watch" "kubernetes-cli" "kustomize" "helm" "hashicorp/tap/terraform" "terragrunt" "kubectx" "jq" "k9s" "shellcheck" "wget" "telnet" "tree" "k6" "fzf" "kubent" "pv" "dialog" "ipcalc" "yq" "helmfile" "awscli" "node" "go" "webp" "autojump" "hashicorp/tap/vault" "yazi" "ffmpeg" "sevenzip" "poppler" "fd" "ripgrep" "zoxide" "resvg" "imagemagick")
brew_cask=("google-chrome" "iterm2" "visual-studio-code" "docker" "raycast" "notion" "google-cloud-sdk" "openvpn-connect" "drawio" "font-meslo-lg-nerd-font")

ENABLE_OH_MY_ZSH=true
ENABLE_FZF_TAB=true
ENABLE_ZSH_AUTOSUGGESTIONS=true
ENABLE_ZSH_SYNTAX_HIGHLIGHTING=true
ENABLE_AUTOJUMP=true
ENABLE_PS1=true
ENABLE_VIMRC=true
ENABLE_ITERM2_PROFILE=true

ENABLE_KUBECOLOR=true
ENABLE_SLIDEV=true
ENABLE_HELM_DIFF=true
ENABLE_GKE_GCLOUD_AUTH_PLUGIN=true
ENABLE_TERRAFORM_AUTOCOMPLETE=true
ENABLE_VAULT_AUTOCOMPLETE=true
ENABLE_AWS_AUTOCOMPLETE=true
ENABLE_K8S_ALIASES=true

source "$SCRIPT_DIR/install-mac-common.sh"
run_mac_install

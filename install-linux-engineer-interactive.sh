#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROFILE_SLUG="linux-engineer-interactive"
PROFILE_TITLE="Linux Install Kit 工程師選單版"
PROFILE_DESCRIPTION="請從選單挑選想安裝的 Ubuntu / Zorin 日常與工程師工具。"
INTERACTIVE_PLATFORM="linux"

apt_prereq_array=("curl" "git" "ca-certificates" "bc")
apt_array=()
snap_array=()
snap_classic_array=()
manual_install_array=()
unsupported_app_array=()

ENABLE_ENGINEER_FEATURES=true
ENABLE_AUTOJUMP=false
ENABLE_SLIDEV=false
ENABLE_HELM_DIFF=false
ENABLE_SHELL_FEATURES=false
ENABLE_SHELL_SETUP=false
ENABLE_YAZI=false
ENABLE_VIMRC=false

source "$SCRIPT_DIR/install-linux-common.sh"
source "$SCRIPT_DIR/install-interactive-common.sh"

linux_engineer_apt=(
  "zsh|Z Shell 終端機，提供更完整的補全與互動功能。"
  "bash-completion|Bash 指令補全，自動提示可用參數。"
  "jq|在終端機讀取、篩選與整理 JSON。"
  "shellcheck|檢查 Shell 腳本常見錯誤。"
  "wget|從網路下載檔案的命令列工具。"
  "telnet|測試 TCP 連線與服務埠。"
  "tree|以樹狀方式列出資料夾結構。"
  "fzf|模糊搜尋工具，快速挑選檔案與指令。"
  "ipcalc|計算 IP、網段與 CIDR 資訊。"
  "hugo|使用 Markdown 建立靜態網站。"
  "golang-go|Go 程式語言與編譯工具。"
  "nodejs|JavaScript 執行環境。"
  "npm|Node.js 套件管理器。"
  "autojump|依常用路徑快速跳轉資料夾。"
  "kubectx|快速切換 Kubernetes context 與 namespace。"
  "wireguard|快速且現代化的 VPN 工具。"
  "openvpn|OpenVPN 命令列 VPN 工具。"
  "network-manager-openvpn-gnome|讓桌面網路管理器使用 OpenVPN。"
  "ffmpeg|轉換與處理影音檔案。"
  "p7zip-full|解壓縮與建立 7z 等壓縮檔。"
  "poppler-utils|提供 PDF 轉文字與圖片工具。"
  "fd-find|更快、更直覺的檔案搜尋工具。"
  "ripgrep|高速搜尋檔案內容。"
  "zoxide|更聰明的資料夾跳轉工具。"
  "imagemagick|圖片轉換、裁切與批次處理工具。"
  "chafa|在終端機顯示圖片預覽。"
  "xclip|在終端機存取 X11 剪貼簿。"
  "unzip|解開 ZIP 壓縮檔。"
  "fontconfig|管理與檢查 Linux 字型。"
)

linux_engineer_snap=(
  "yq|處理 YAML 與 JSON 設定檔。"
  "drawio|繪製流程圖與架構圖。"
  "kubectl|Kubernetes 指令列工具。"
  "helm|Kubernetes 套件管理器。"
  "aws-cli|在終端機管理 AWS 資源。"
  "code|Visual Studio Code 程式碼編輯器。"
  "docker|容器執行環境與管理工具。"
)

linux_engineer_manual=(
  "k9s|Kubernetes 終端機 UI，快速瀏覽與操作叢集。"
  "kustomize|用宣告式方式管理 Kubernetes 設定。"
  "terragrunt|簡化 Terraform 多環境與模組管理。"
  "terraform|以程式碼管理雲端與基礎設施。"
  "gcloud|Google Cloud 資源管理工具。"
  "google-chrome|Google Chrome 網頁瀏覽器。"
)

linux_shell_features=(
  "shell-base|Shell 基礎環境：oh-my-zsh、外掛與 zsh 設定。"
  "autojump|依常用路徑快速跳轉資料夾。"
  "yazi|終端機檔案管理器，支援預覽與搜尋。"
  "vimrc|套用專案提供的 Vim 基本設定。"
)

linux_engineer_features=(
  "slidev|用 Markdown 製作開發者簡報。"
  "helm-diff|在套用 Helm 前預覽資源差異。"
  "gke-auth|安裝 GKE 存取 Kubernetes 所需外掛。"
  "terraform-autocomplete|安裝 Terraform 並啟用指令補全。"
)

add_item() {
  local array_name="$1"
  local value="$2"
  local item
  eval "for item in \"\${${array_name}[@]}\"; do [ \"\$item\" = \"\$value\" ] && return; done"
  eval "${array_name}+=(\"\$value\")"
}

apply_linux_engineer_apt() { add_item apt_array "$1"; }
apply_linux_engineer_snap() { add_item snap_array "$1"; }

apply_linux_engineer_manual() {
  add_item manual_install_array "$1"
  add_item apt_prereq_array wget
  case "$1" in
    k9s) add_item apt_prereq_array jq ;;
    gcloud|terraform) add_item apt_prereq_array gnupg; add_item apt_prereq_array lsb-release; add_item apt_prereq_array software-properties-common ;;
  esac
}

apply_linux_shell_selection() {
  case "$1" in
    shell-base)
      ENABLE_SHELL_FEATURES=true
      ENABLE_SHELL_SETUP=true
      add_item apt_array zsh
      ;;
    autojump)
      ENABLE_AUTOJUMP=true
      ENABLE_SHELL_FEATURES=true
      ENABLE_SHELL_SETUP=true
      add_item apt_array zsh
      add_item apt_array autojump
      ;;
    yazi)
      ENABLE_YAZI=true
      add_item apt_array fd-find
      add_item apt_array ripgrep
      ;;
    vimrc)
      ENABLE_VIMRC=true
      add_item apt_prereq_array vim
      ;;
  esac
}

apply_linux_engineer_feature_selection() {
  case "$1" in
    slidev)
      ENABLE_SLIDEV=true
      add_item apt_array nodejs
      add_item apt_array npm
      ;;
    helm-diff)
      ENABLE_HELM_DIFF=true
      add_item snap_classic_array helm
      ;;
    gke-auth)
      add_item manual_install_array gcloud
      add_item apt_prereq_array wget
      ;;
    terraform-autocomplete)
      add_item manual_install_array terraform
      add_item apt_prereq_array wget
      add_item apt_prereq_array gnupg
      add_item apt_prereq_array lsb-release
      add_item apt_prereq_array software-properties-common
      ;;
  esac
}

prepare_interactive_menu || exit 1

menu_select "選擇 Linux 工程師 apt 工具（空白鍵選取，Enter 確認）" "${linux_engineer_apt[@]}"
for_each_menu_selection "$MENU_SELECTIONS" apply_linux_engineer_apt

menu_select "選擇 Linux 工程師 snap 應用程式" "${linux_engineer_snap[@]}"
for_each_menu_selection "$MENU_SELECTIONS" apply_linux_engineer_snap

menu_select "選擇 Linux 工程師外部下載工具" "${linux_engineer_manual[@]}"
for_each_menu_selection "$MENU_SELECTIONS" apply_linux_engineer_manual

menu_select "選擇 Shell 與設定功能" "${linux_shell_features[@]}"
for_each_menu_selection "$MENU_SELECTIONS" apply_linux_shell_selection

menu_select "選擇工程師額外設定" "${linux_engineer_features[@]}"
for_each_menu_selection "$MENU_SELECTIONS" apply_linux_engineer_feature_selection

echo ""
echo "已選擇的 apt 套件：${apt_array[*]:-無}"
echo "已選擇的 snap 套件：${snap_array[*]:-無}"
echo "已選擇的 snap classic 套件：${snap_classic_array[*]:-無}"
echo "已選擇的外部下載工具：${manual_install_array[*]:-無}"
echo "即將開始安裝；必要依賴可能會一併安裝。"
run_linux_install

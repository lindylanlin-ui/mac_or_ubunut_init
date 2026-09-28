#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROFILE_SLUG="linux-interactive"
PROFILE_TITLE="Linux Install Kit 日常選單版"
PROFILE_DESCRIPTION="請從選單挑選想安裝的 Ubuntu / Zorin 日常工具。"
INTERACTIVE_PLATFORM="linux"

apt_prereq_array=("curl" "git" "ca-certificates" "bc")
apt_array=()
snap_array=()
snap_classic_array=()
manual_install_array=()
unsupported_app_array=()

ENABLE_ENGINEER_FEATURES=false
ENABLE_AUTOJUMP=false
ENABLE_ZOXIDE=false
ENABLE_SLIDEV=false
ENABLE_HELM_DIFF=false
ENABLE_SHELL_FEATURES=false
ENABLE_SHELL_SETUP=false
ENABLE_YAZI=false
ENABLE_VIMRC=false

source "$SCRIPT_DIR/install-linux-common.sh"
source "$SCRIPT_DIR/install-interactive-common.sh"

linux_daily_apt=(
  "zsh|Z Shell 終端機，提供更完整的補全與互動功能。"
  "bash-completion|Bash 指令補全，自動提示可用參數。"
  "jq|在終端機讀取、篩選與整理 JSON。"
  "shellcheck|檢查 Shell 腳本常見錯誤。"
  "wget|從網路下載檔案的命令列工具。"
  "telnet|測試 TCP 連線與服務埠。"
  "tree|以樹狀方式列出資料夾結構。"
  "fzf|模糊搜尋工具，快速挑選檔案與指令。"
  "pv|顯示資料流處理進度。"
  "webp|提供 WebP 圖片處理工具。"
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

linux_daily_snap=(
  "yq|處理 YAML 與 JSON 設定檔。"
  "drawio|繪製流程圖與架構圖。"
  "firefox|Mozilla Firefox 網頁瀏覽器。"
  "code|Visual Studio Code 程式碼編輯器。"
)

linux_daily_manual=(
  "google-chrome|Google Chrome 網頁瀏覽器。"
  "brave-browser|注重隱私與廣告阻擋的網頁瀏覽器。"
  "microsoft-edge|Microsoft Edge 網頁瀏覽器。"
  "eza|更現代、支援色彩與圖示的 ls 替代工具。"
)

linux_shell_features=(
  "shell-base|Shell 基礎環境：oh-my-zsh、外掛與 zsh 設定。"
  "autojump|依常用路徑快速跳轉資料夾。"
  "zoxide-config|啟用 zoxide 的 z 與 zi 指令。"
  "yazi|終端機檔案管理器，支援預覽與搜尋。"
  "vimrc|套用專案提供的 Vim 基本設定。"
)

add_item() {
  local array_name="$1"
  local value="$2"
  local item
  eval "for item in \"\${${array_name}[@]}\"; do [ \"\$item\" = \"\$value\" ] && return; done"
  eval "${array_name}+=(\"\$value\")"
}

apply_linux_daily_apt() {
  add_item apt_array "$1"
  if [ "$1" = "zoxide" ]; then
    ENABLE_ZOXIDE=true
    add_item apt_array zsh
  fi
}
apply_linux_daily_snap() {
  case "$1" in
    code) add_item snap_classic_array "$1" ;;
    *) add_item snap_array "$1" ;;
  esac
}
apply_linux_daily_manual() {
  add_item manual_install_array "$1"
  add_item apt_prereq_array wget
  if [ "$1" = "eza" ]; then
    add_item apt_prereq_array gnupg
  fi
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
    zoxide-config)
      ENABLE_ZOXIDE=true
      add_item apt_array zoxide
      add_item apt_array zsh
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

prepare_interactive_menu || exit 1

menu_select "選擇 Linux 日常 apt 工具（空白鍵選取，Enter 確認）" "${linux_daily_apt[@]}"
for_each_menu_selection "$MENU_SELECTIONS" apply_linux_daily_apt

menu_select "選擇 Linux 日常 snap 應用程式" "${linux_daily_snap[@]}"
for_each_menu_selection "$MENU_SELECTIONS" apply_linux_daily_snap

menu_select "選擇 Linux 日常外部下載應用程式" "${linux_daily_manual[@]}"
for_each_menu_selection "$MENU_SELECTIONS" apply_linux_daily_manual

menu_select "選擇 Shell 與設定功能" "${linux_shell_features[@]}"
for_each_menu_selection "$MENU_SELECTIONS" apply_linux_shell_selection

echo ""
echo "已選擇的 apt 套件：${apt_array[*]:-無}"
echo "已選擇的 snap 套件：${snap_array[*]:-無}"
echo "已選擇的 snap classic 套件：${snap_classic_array[*]:-無}"
echo "已選擇的外部下載工具：${manual_install_array[*]:-無}"
echo "即將開始安裝；必要依賴可能會一併安裝。"
run_linux_install

#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROFILE_SLUG="mac-interactive"
PROFILE_TITLE="mac-install macOS 選單版"
PROFILE_DESCRIPTION="請從選單挑選想安裝的 macOS 日常工具與設定。"
INTERACTIVE_PLATFORM="mac"

brew_tap_array=()
brew_array=()
brew_cask=()

ENABLE_OH_MY_ZSH=false
ENABLE_FZF_TAB=false
ENABLE_ZSH_AUTOSUGGESTIONS=false
ENABLE_ZSH_SYNTAX_HIGHLIGHTING=false
ENABLE_AUTOJUMP=false
ENABLE_ZOXIDE=false
ENABLE_PS1=false
ENABLE_VIMRC=false
ENABLE_ITERM2_PROFILE=false
ENABLE_YAZI=false

source "$SCRIPT_DIR/install-mac-common.sh"
source "$SCRIPT_DIR/install-interactive-common.sh"

mac_daily_formulas=(
  "zsh|Z Shell 終端機，提供更完整的補全與互動功能。"
  "bash-completion|Bash 指令補全，自動提示可用參數。"
  "jq|在終端機讀取、篩選與整理 JSON。"
  "shellcheck|檢查 Shell 腳本常見錯誤。"
  "wget|從網路下載檔案的命令列工具。"
  "telnet|測試 TCP 連線與服務埠。"
  "tree|以樹狀方式列出資料夾結構。"
  "fzf|模糊搜尋工具，快速挑選檔案與指令。"
  "pv|顯示資料流處理進度。"
  "yq|處理 YAML 與 JSON 設定檔。"
  "webp|提供 WebP 圖片處理工具。"
  "autojump|依常用路徑快速跳轉資料夾。"
  "yazi|終端機檔案管理器，支援預覽與搜尋。"
  "ffmpeg|轉換與處理影音檔案。"
  "sevenzip|解壓縮與建立 7z 等壓縮檔。"
  "poppler|提供 PDF 轉文字與圖片工具。"
  "fd|更快、更直覺的檔案搜尋工具。"
  "ripgrep|高速搜尋檔案內容。"
  "zoxide|更聰明的資料夾跳轉工具。"
  "resvg|將 SVG 渲染成 PNG 等圖片格式。"
  "imagemagick|圖片轉換、裁切與批次處理工具。"
)

mac_daily_casks=(
  "google-chrome|Google Chrome 網頁瀏覽器。"
  "brave-browser|注重隱私與廣告阻擋的網頁瀏覽器。"
  "firefox|Mozilla Firefox 網頁瀏覽器。"
  "microsoft-edge|Microsoft Edge 網頁瀏覽器。"
  "iterm2|macOS 終端機，支援分頁與高階設定。"
  "visual-studio-code|程式碼編輯器與擴充套件平台。"
  "raycast|快速啟動器與工作流程工具。"
  "openvpn-connect|OpenVPN 官方 VPN 用戶端。"
  "drawio|繪製流程圖與架構圖。"
  "font-meslo-lg-nerd-font|含圖示的終端機字型。"
)

mac_shell_features=(
  "oh-my-zsh|Zsh 設定框架，集中管理主題與外掛。"
  "fzf-tab|將 Tab 補全改為可搜尋的選單。"
  "zsh-autosuggestions|依歷史指令提供輸入建議。"
  "zsh-syntax-highlighting|在輸入時標示指令語法。"
  "autojump-config|啟用 autojump 的 Zsh 外掛。"
  "zoxide-config|啟用 zoxide 的 z 與 zi 指令。"
  "ps1|顯示使用者、路徑與 Git 狀態提示字元。"
  "vimrc|套用專案提供的 Vim 基本設定。"
  "yazi-config|同步 Yazi 主題、快捷鍵與路徑功能。"
  "iterm2-profile|匯入專案提供的 iTerm2 Profile。"
)

add_brew_formula() {
  local item
  for item in "${brew_array[@]}"; do
    [ "$item" = "$1" ] && return
  done
  brew_array+=("$1")
}

add_brew_cask() {
  local item
  for item in "${brew_cask[@]}"; do
    [ "$item" = "$1" ] && return
  done
  brew_cask+=("$1")
}

apply_mac_formula() {
  add_brew_formula "$1"
  if [ "$1" = "zoxide" ]; then
    ENABLE_ZOXIDE=true
  fi
}

apply_mac_shell_selection() {
  case "$1" in
    oh-my-zsh)
      ENABLE_OH_MY_ZSH=true
      add_brew_formula zsh
      ;;
    fzf-tab)
      ENABLE_FZF_TAB=true
      ENABLE_OH_MY_ZSH=true
      add_brew_formula zsh
      ;;
    zsh-autosuggestions)
      ENABLE_ZSH_AUTOSUGGESTIONS=true
      ENABLE_OH_MY_ZSH=true
      add_brew_formula zsh
      ;;
    zsh-syntax-highlighting)
      ENABLE_ZSH_SYNTAX_HIGHLIGHTING=true
      ENABLE_OH_MY_ZSH=true
      add_brew_formula zsh
      ;;
    autojump-config)
      ENABLE_AUTOJUMP=true
      ENABLE_OH_MY_ZSH=true
      add_brew_formula zsh
      add_brew_formula autojump
      ;;
    zoxide-config)
      ENABLE_ZOXIDE=true
      add_brew_formula zoxide
      ;;
    ps1) ENABLE_PS1=true ;;
    vimrc) ENABLE_VIMRC=true ;;
    yazi-config)
      ENABLE_YAZI=true
      add_brew_formula yazi
      ;;
    iterm2-profile)
      ENABLE_ITERM2_PROFILE=true
      add_brew_cask iterm2
      ;;
  esac
}

prepare_interactive_menu || exit 1

menu_select "選擇 macOS 日常 CLI 工具（空白鍵選取，Enter 確認）" "${mac_daily_formulas[@]}"
for_each_menu_selection "$MENU_SELECTIONS" apply_mac_formula

menu_select "選擇 macOS 日常 GUI 應用程式" "${mac_daily_casks[@]}"
for_each_menu_selection "$MENU_SELECTIONS" add_brew_cask

menu_select "選擇 Shell 與設定功能" "${mac_shell_features[@]}"
for_each_menu_selection "$MENU_SELECTIONS" apply_mac_shell_selection

echo ""
echo "已選擇的 Homebrew 套件：${brew_array[*]:-無}"
echo "已選擇的 macOS App：${brew_cask[*]:-無}"
echo "即將開始安裝；共用依賴可能會一併安裝。"
run_mac_install

#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROFILE_SLUG="mac-engineer-interactive"
PROFILE_TITLE="mac-install macOS 工程師選單版"
PROFILE_DESCRIPTION="請從選單挑選想安裝的 macOS 日常與工程師工具。"
INTERACTIVE_PLATFORM="mac"

brew_tap_array=()
brew_array=()
brew_cask=()

ENABLE_OH_MY_ZSH=false
ENABLE_FZF_TAB=false
ENABLE_ZSH_AUTOSUGGESTIONS=false
ENABLE_ZSH_SYNTAX_HIGHLIGHTING=false
ENABLE_AUTOJUMP=false
ENABLE_PS1=false
ENABLE_VIMRC=false
ENABLE_ITERM2_PROFILE=false
ENABLE_YAZI=false
ENABLE_KUBECOLOR=false
ENABLE_SLIDEV=false
ENABLE_HELM_DIFF=false
ENABLE_GKE_GCLOUD_AUTH_PLUGIN=false
ENABLE_TERRAFORM_AUTOCOMPLETE=false
ENABLE_VAULT_AUTOCOMPLETE=false
ENABLE_AWS_AUTOCOMPLETE=false
ENABLE_K8S_ALIASES=false

source "$SCRIPT_DIR/install-mac-common.sh"
source "$SCRIPT_DIR/install-interactive-common.sh"

mac_engineer_formulas=(
  "zsh|Z Shell 終端機，提供更完整的補全與互動功能。"
  "bash-completion|Bash 指令補全，自動提示可用參數。"
  "watch|定期重複執行指令並更新畫面。"
  "kubernetes-cli|Kubernetes 指令列工具 kubectl。"
  "kustomize|用宣告式方式管理 Kubernetes 設定。"
  "helm|Kubernetes 套件管理器。"
  "terraform|以程式碼管理雲端與基礎設施。"
  "terragrunt|簡化 Terraform 多環境與模組管理。"
  "kubectx|快速切換 Kubernetes context 與 namespace。"
  "jq|在終端機讀取、篩選與整理 JSON。"
  "k9s|Kubernetes 終端機 UI，快速瀏覽與操作叢集。"
  "shellcheck|檢查 Shell 腳本常見錯誤。"
  "wget|從網路下載檔案的命令列工具。"
  "telnet|測試 TCP 連線與服務埠。"
  "tree|以樹狀方式列出資料夾結構。"
  "k6|以 JavaScript 撰寫 API 與負載測試。"
  "fzf|模糊搜尋工具，快速挑選檔案與指令。"
  "kubent|找出 Kubernetes 中已淘汰的 API。"
  "pv|顯示資料流處理進度。"
  "dialog|在終端機顯示互動式選單。"
  "ipcalc|計算 IP、網段與 CIDR 資訊。"
  "yq|處理 YAML 與 JSON 設定檔。"
  "helmfile|以檔案宣告與管理 Helm releases。"
  "awscli|在終端機管理 AWS 資源。"
  "node|JavaScript 執行環境與 npm。"
  "go|Go 程式語言與開發工具鏈。"
  "vault|集中管理與存取機密資料。"
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

mac_engineer_casks=(
  "google-chrome|Google Chrome 網頁瀏覽器。"
  "brave-browser|注重隱私與廣告阻擋的網頁瀏覽器。"
  "firefox|Mozilla Firefox 網頁瀏覽器。"
  "microsoft-edge|Microsoft Edge 網頁瀏覽器。"
  "iterm2|macOS 終端機，支援分頁與高階設定。"
  "visual-studio-code|程式碼編輯器與擴充套件平台。"
  "docker|容器執行環境與管理工具。"
  "raycast|快速啟動器與工作流程工具。"
  "notion|筆記、文件與團隊協作工具。"
  "google-cloud-sdk|管理 Google Cloud 資源的 CLI。"
  "openvpn-connect|OpenVPN 官方 VPN 用戶端。"
  "drawio|繪製流程圖與架構圖。"
  "font-meslo-lg-nerd-font|含圖示的終端機字型。"
  "chatgpt|OpenAI 官方 ChatGPT 桌面應用程式。"
  "antigravity|Google Antigravity 智慧代理平台。"
  "claude|Anthropic 官方 Claude 桌面應用程式。"
  "google-gemini|Google Gemini 原生桌面助理。"
)

mac_shell_features=(
  "oh-my-zsh|Zsh 設定框架，集中管理主題與外掛。"
  "fzf-tab|將 Tab 補全改為可搜尋的選單。"
  "zsh-autosuggestions|依歷史指令提供輸入建議。"
  "zsh-syntax-highlighting|在輸入時標示指令語法。"
  "autojump-config|啟用 autojump 的 Zsh 外掛。"
  "ps1|顯示使用者、路徑與 Git 狀態提示字元。"
  "vimrc|套用專案提供的 Vim 基本設定。"
  "yazi-config|同步 Yazi 主題、快捷鍵與路徑功能。"
  "iterm2-profile|匯入專案提供的 iTerm2 Profile。"
)

mac_engineer_features=(
  "kubecolor|用顏色顯示 kubectl 輸出，提高閱讀性。"
  "slidev|用 Markdown 製作開發者簡報。"
  "helm-diff|在套用 Helm 前預覽資源差異。"
  "gke-auth|安裝 GKE 存取 Kubernetes 所需外掛。"
  "terraform-autocomplete|啟用 Terraform 指令補全。"
  "vault-autocomplete|啟用 Vault 指令補全。"
  "aws-autocomplete|啟用 AWS CLI 指令補全。"
  "k8s-aliases|加入 k、kns、ktx 等 Kubernetes alias。"
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

add_brew_tap() {
  local item
  for item in "${brew_tap_array[@]}"; do
    [ "$item" = "$1" ] && return
  done
  brew_tap_array+=("$1")
}

apply_mac_engineer_formula() {
  case "$1" in
    terraform)
      add_brew_tap hashicorp/tap
      add_brew_formula hashicorp/tap/terraform
      ;;
    vault)
      add_brew_tap hashicorp/tap
      add_brew_formula hashicorp/tap/vault
      ;;
    *) add_brew_formula "$1" ;;
  esac
}

apply_mac_shell_selection() {
  case "$1" in
    oh-my-zsh) ENABLE_OH_MY_ZSH=true; add_brew_formula zsh ;;
    fzf-tab) ENABLE_FZF_TAB=true; ENABLE_OH_MY_ZSH=true; add_brew_formula zsh ;;
    zsh-autosuggestions) ENABLE_ZSH_AUTOSUGGESTIONS=true; ENABLE_OH_MY_ZSH=true; add_brew_formula zsh ;;
    zsh-syntax-highlighting) ENABLE_ZSH_SYNTAX_HIGHLIGHTING=true; ENABLE_OH_MY_ZSH=true; add_brew_formula zsh ;;
    autojump-config) ENABLE_AUTOJUMP=true; ENABLE_OH_MY_ZSH=true; add_brew_formula zsh; add_brew_formula autojump ;;
    ps1) ENABLE_PS1=true ;;
    vimrc) ENABLE_VIMRC=true ;;
    yazi-config) ENABLE_YAZI=true; add_brew_formula yazi ;;
    iterm2-profile) ENABLE_ITERM2_PROFILE=true; add_brew_cask iterm2 ;;
  esac
}

apply_mac_engineer_selection() {
  case "$1" in
    kubecolor) ENABLE_KUBECOLOR=true; add_brew_tap hidetatz/tap ;;
    slidev) ENABLE_SLIDEV=true; add_brew_formula node ;;
    helm-diff) ENABLE_HELM_DIFF=true; add_brew_formula helm ;;
    gke-auth) ENABLE_GKE_GCLOUD_AUTH_PLUGIN=true; add_brew_cask google-cloud-sdk ;;
    terraform-autocomplete) ENABLE_TERRAFORM_AUTOCOMPLETE=true; apply_mac_engineer_formula terraform ;;
    vault-autocomplete) ENABLE_VAULT_AUTOCOMPLETE=true; apply_mac_engineer_formula vault ;;
    aws-autocomplete) ENABLE_AWS_AUTOCOMPLETE=true; add_brew_formula awscli ;;
    k8s-aliases) ENABLE_K8S_ALIASES=true; add_brew_formula kubernetes-cli; add_brew_formula kubectx ;;
  esac
}

prepare_interactive_menu || exit 1

menu_select "選擇 macOS 工程師 CLI 工具（空白鍵選取，Enter 確認）" "${mac_engineer_formulas[@]}"
for_each_menu_selection "$MENU_SELECTIONS" apply_mac_engineer_formula

menu_select "選擇 macOS 工程師 GUI 與 AI 應用程式" "${mac_engineer_casks[@]}"
for_each_menu_selection "$MENU_SELECTIONS" add_brew_cask

menu_select "選擇 Shell 與設定功能" "${mac_shell_features[@]}"
for_each_menu_selection "$MENU_SELECTIONS" apply_mac_shell_selection

menu_select "選擇工程師額外設定" "${mac_engineer_features[@]}"
for_each_menu_selection "$MENU_SELECTIONS" apply_mac_engineer_selection

echo ""
echo "已選擇的 Homebrew 套件：${brew_array[*]:-無}"
echo "已選擇的 macOS App：${brew_cask[*]:-無}"
echo "即將開始安裝；共用依賴可能會一併安裝。"
run_mac_install

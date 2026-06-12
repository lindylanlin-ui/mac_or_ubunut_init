#!/bin/bash

#=========================================
# 參數設定
# 預設的 - 完整版 (適用於 Ubuntu/Zorin OS)
# apt_array=("zsh" "bash-completion" "wget" "curl" "git" "jq" "tree" "telnet" "build-essential" "apt-transport-https" "ca-certificates" "gnupg" "lsb-release" "software-properties-common" "python3-pip" "fzf" "dialog" "bc" "vim" "net-tools" "ipcalc" "shellcheck" "hugo" "golang-go" "nodejs" "npm" "autojump" "kubectx")
# snap_array=("yq")
# snap_classic_array=("code" "docker") # 需要 --classic 的 snap 套件
# manual_install_array=("k9s" "kustomize" "terragrunt" "terraform" "gcloud" "google-chrome" "docker-desktop")

# tuffy使用
apt_array=("zsh" "bash-completion" "wget" "curl" "git" "jq" "tree" "telnet" "build-essential" "apt-transport-https" "ca-certificates" "gnupg" "lsb-release" "software-properties-common" "python3-pip" "fzf" "dialog" "bc" "vim" "net-tools" "ipcalc" "shellcheck" "hugo" "golang-go" "nodejs" "npm" "autojump" "kubectx")
snap_array=("yq")
snap_classic_array=("kubectl" "helm" "aws-cli" "code" "docker")
manual_install_array=("k9s" "kustomize" "terragrunt" "terraform" "gcloud" "google-chrome")

# 精簡版 - 不含 K8s/Cloud 工具
# apt_array=("zsh" "bash-completion" "wget" "curl" "git" "jq" "tree" "build-essential" "python3-pip" "fzf" "vim" "autojump" "nodejs" "npm")
# snap_array=()
# snap_classic_array=("code" "docker")
# manual_install_array=("google-chrome")

# 最小版 - 僅開發必要工具
# apt_array=("zsh" "bash-completion" "git" "jq" "tree" "fzf" "vim" "curl" "wget")
# snap_array=()
# snap_classic_array=("code")
# manual_install_array=("google-chrome")

#=========================================
# 腳本設定
nowtime=$(date '+%Y/%m/%d %H:%M:%S')
num=0
changed_count=0
already_count=0
failed_count=0

#=========================================
# 顏色設定
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'
NC=$'\033[0m' # 重置颜色

#=========================================
# 輔助函式

# 檢查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 輸出訊息
print_msg() {
    printf "%2d _ %s : [%s%s%s]\n" "$num" "$1" "$2" "$3" "${NC}"
}

print_error_log() {
    local log_file="$1"
    if [ -s "$log_file" ]; then
        echo "   錯誤摘要:"
        sed -n '1,8p' "$log_file" | sed 's/^/   /'
    fi
}

# 安裝套件 (通用邏輯)
install_pkg() {
    local pkg_name="$1"
    local install_cmd="$2"
    local check_cmd="$3"
    local msg="$4"
    local log_file

    num="$((num + 1))"
    if eval "$check_cmd"; then
        already_count="$((already_count + 1))"
        print_msg "$msg" "${YELLOW}" "已安裝"
    else
        log_file=$(mktemp)
        if bash -lc "$install_cmd" >"$log_file" 2>&1; then
            changed_count="$((changed_count + 1))"
            print_msg "$msg" "${GREEN}" "安裝成功"
        else
            failed_count="$((failed_count + 1))"
            print_msg "$msg" "${RED}" "安裝失敗"
            print_error_log "$log_file"
        fi
        rm -f "$log_file"
    fi
}

# 新增設定到檔案
append_to_file() {
    local line="$1"
    local file="$2"
    local msg="$3"
    num="$((num + 1))"
    if ! grep -qF -- "$line" "$file"; then
        changed_count="$((changed_count + 1))"
        echo "$line" | sudo tee -a "$file" >/dev/null
        print_msg "$msg" "${GREEN}" "設定成功"
    else
        already_count="$((already_count + 1))"
        print_msg "$msg" "${YELLOW}" "已設定"
    fi
}

# 依照目前標準模板寫入 .zshrc
sync_zshrc() {
    local file="$HOME/.zshrc"
    local tmp_file
    tmp_file=$(mktemp)

    cat <<'EOF' > "$tmp_file"
# =====================================================================
# Oh My Zsh 基本設定
# =====================================================================
export ZSH="$HOME/.oh-my-zsh"
export ZSH_THEME="clean"

plugins=(
  git
  aws
  kubectl
  terraform
  fzf-tab
  zsh-autosuggestions
  zsh-syntax-highlighting
  autojump
  kube-ps1
)

source "$ZSH/oh-my-zsh.sh"

# =====================================================================
# PATH 與常用工具
# =====================================================================
typeset -U path PATH
path=(
  "$HOME/.local/bin"
  /usr/local/bin
  /snap/bin
  $path
)
export PATH

if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
fi

if [ -f /usr/share/doc/fzf/examples/completion.zsh ]; then
  source /usr/share/doc/fzf/examples/completion.zsh
fi

[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"

# 保留 ls 顏色，但取消特殊資料夾的底色顯示
export LS_COLORS="${LS_COLORS}:st=01;34:ow=01;34:tw=01;34"

# =====================================================================
# Completion
# =====================================================================
autoload -U +X bashcompinit && bashcompinit

if command -v kubectl >/dev/null 2>&1; then
  source <(kubectl completion zsh)
fi

if command -v terraform >/dev/null 2>&1; then
  complete -o nospace -C "$(command -v terraform)" terraform
fi

if [ -f "$HOME/.terragrunt-completion.zsh" ]; then
  source "$HOME/.terragrunt-completion.zsh"
fi

# =====================================================================
# Prompt 與偏好設定
# =====================================================================
setopt promptsubst

if (( ${+functions[kube_ps1]} )); then
  RPROMPT='$(kube_ps1)'
fi

HISTFILE="$HOME/.zsh_history"
HISTSIZE=5000
SAVEHIST=5000
setopt hist_ignore_dups
setopt share_history

# =====================================================================
# Aliases
# =====================================================================
alias k="kubectl"
alias kns="kubens"
alias ktx="kubectx"
EOF

    num="$((num + 1))"
    if [ -f "$file" ] && cmp -s "$tmp_file" "$file"; then
        already_count="$((already_count + 1))"
        print_msg "同步 .zshrc" "${YELLOW}" "已設定"
    else
        changed_count="$((changed_count + 1))"
        cp "$tmp_file" "$file"
        print_msg "同步 .zshrc" "${GREEN}" "設定成功"
    fi

    rm -f "$tmp_file"
}

echo -e "============================== Linux Install Kit 腳本 =============================="
echo -e "本腳本會自動安裝所需套件（適用於 Ubuntu/Zorin OS）"
echo -e "腳本開始時間 ${nowtime}"

#=========================================

# 檢查是否為 root 或有 sudo 權限
if [[ $EUID -ne 0 ]] && ! sudo -v; then
    echo -e "${RED}此腳本需要 sudo 權限，請確認您有 sudo 權限${NC}"
    exit 1
fi

# 更新 apt 套件列表
num="$((num + 1))"
echo -e "${num} _ 更新 apt 套件列表..."
if sudo apt update -qq; then
    changed_count="$((changed_count + 1))"
    printf "%2d _ 更新 apt 套件列表 : [${GREEN}更新成功${NC}]\n" "$num"
else
    failed_count="$((failed_count + 1))"
    printf "%2d _ 更新 apt 套件列表 : [${RED}更新失敗${NC}]\n" "$num"
fi

# 安裝 apt 套件
for kit in "${apt_array[@]}"; do
    num="$((num + 1))"
    if ! dpkg -l | grep -q -w "^ii  $kit"; then
        if sudo apt install -y "$kit" -qq; then
            changed_count="$((changed_count + 1))"
            print_msg "安裝 apt 套件 ($kit)" "${GREEN}" "安裝成功"
        else
            failed_count="$((failed_count + 1))"
            print_msg "安裝 apt 套件 ($kit)" "${RED}" "安裝失敗"
        fi
    else
        already_count="$((already_count + 1))"
        print_msg "安裝 apt 套件 ($kit)" "${YELLOW}" "已安裝"
    fi
done

# 安裝 snapd（如果尚未安裝）
num="$((num + 1))"
if ! command_exists snap; then
    if sudo apt install -y snapd -qq; then
        changed_count="$((changed_count + 1))"
        print_msg "安裝 snapd" "${GREEN}" "安裝成功"
    else
        failed_count="$((failed_count + 1))"
        print_msg "安裝 snapd" "${RED}" "安裝失敗"
    fi
else
    already_count="$((already_count + 1))"
    print_msg "安裝 snapd" "${YELLOW}" "已安裝"
fi

# 安裝 snap 套件
for kit in "${snap_array[@]}"; do
    num="$((num + 1))"
    if ! snap list "$kit" >/dev/null 2>&1; then
        if sudo snap install "$kit"; then
            changed_count="$((changed_count + 1))"
            print_msg "安裝 snap 套件 ($kit)" "${GREEN}" "安裝成功"
        else
            failed_count="$((failed_count + 1))"
            print_msg "安裝 snap 套件 ($kit)" "${RED}" "安裝失敗"
        fi
    else
        already_count="$((already_count + 1))"
        print_msg "安裝 snap 套件 ($kit)" "${YELLOW}" "已安裝"
    fi
done

# 安裝 snap 套件 (需要 --classic)
for kit in "${snap_classic_array[@]}"; do
    num="$((num + 1))"
    if ! snap list "$kit" >/dev/null 2>&1; then
        if sudo snap install "$kit" --classic; then
            changed_count="$((changed_count + 1))"
            print_msg "安裝 snap 套件 --classic ($kit)" "${GREEN}" "安裝成功"
        else
            failed_count="$((failed_count + 1))"
            print_msg "安裝 snap 套件 --classic ($kit)" "${RED}" "安裝失敗"
        fi
    else
        already_count="$((already_count + 1))"
        print_msg "安裝 snap 套件 --classic ($kit)" "${YELLOW}" "已安裝"
    fi
done

# 手動安裝 kustomize
if [[ " ${manual_install_array[@]} " =~ " k9s " ]]; then
    num="$((num + 1))"
    if ! command_exists k9s; then
        K9S_VERSION=$(curl -fsSL https://api.github.com/repos/derailed/k9s/releases/latest | jq -r '.tag_name')
        if (
            wget -q "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz" -O k9s_Linux_amd64.tar.gz &&
            tar -xzf k9s_Linux_amd64.tar.gz k9s &&
            chmod +x k9s &&
            sudo mv k9s /usr/local/bin/k9s &&
            rm -f k9s_Linux_amd64.tar.gz
        ); then
            changed_count="$((changed_count + 1))"
            print_msg "安裝 k9s" "${GREEN}" "安裝成功"
        else
            failed_count="$((failed_count + 1))"
            print_msg "安裝 k9s" "${RED}" "安裝失敗"
        fi
    else
        already_count="$((already_count + 1))"
        print_msg "安裝 k9s" "${YELLOW}" "已安裝"
    fi
fi

# 手動安裝 kustomize
if [[ " ${manual_install_array[@]} " =~ " kustomize " ]]; then
    num="$((num + 1))"
    if ! command_exists kustomize; then
        if (curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash && sudo mv kustomize /usr/local/bin/); then
            changed_count="$((changed_count + 1))"
            print_msg "安裝 kustomize" "${GREEN}" "安裝成功"
        else
            failed_count="$((failed_count + 1))"
            print_msg "安裝 kustomize" "${RED}" "安裝失敗"
        fi
    else
        already_count="$((already_count + 1))"
        print_msg "安裝 kustomize" "${YELLOW}" "已安裝"
    fi
fi

# 手動安裝 terragrunt
if [[ " ${manual_install_array[@]} " =~ " terragrunt " ]]; then
    num="$((num + 1))"
    if ! command_exists terragrunt; then
        TERRAGRUNT_VERSION=$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | grep tag_name | cut -d '"' -f 4)
        if (wget -q "https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_linux_amd64" -O terragrunt && chmod +x terragrunt && sudo mv terragrunt /usr/local/bin/); then
            changed_count="$((changed_count + 1))"
            print_msg "安裝 terragrunt" "${GREEN}" "安裝成功"
        else
            failed_count="$((failed_count + 1))"
            print_msg "安裝 terragrunt" "${RED}" "安裝失敗"
        fi
    else
        already_count="$((already_count + 1))"
        print_msg "安裝 terragrunt" "${YELLOW}" "已安裝"
    fi
fi

# 手動安裝 Terraform (HashiCorp 官方 APT Repository)
if [[ " ${manual_install_array[@]} " =~ " terraform " ]]; then
    num="$((num + 1))"
    if ! command_exists terraform; then
        source /etc/os-release
        curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${UBUNTU_CODENAME} main" | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
        sudo apt update -qq
        if sudo apt install -y terraform -qq; then
            changed_count="$((changed_count + 1))"
            print_msg "安裝 Terraform" "${GREEN}" "安裝成功"
        else
            failed_count="$((failed_count + 1))"
            print_msg "安裝 Terraform" "${RED}" "安裝失敗"
        fi
    else
        already_count="$((already_count + 1))"
        print_msg "安裝 Terraform" "${YELLOW}" "已安裝"
    fi
fi

# 手動安裝 Google Cloud SDK
if [[ " ${manual_install_array[@]} " =~ " gcloud " ]]; then
    install_pkg "gcloud" \
        "curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/cloud.google.gpg && echo 'deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main' | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null && sudo apt update -qq && sudo apt install -y google-cloud-sdk -qq" \
        "command_exists gcloud" \
        "安裝 Google Cloud SDK"
fi

# 手動安裝 Google Chrome
if [[ " ${manual_install_array[@]} " =~ " google-chrome " ]]; then
    install_pkg "google-chrome" \
        "wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && sudo apt install -y ./google-chrome-stable_current_amd64.deb -qq && rm -f google-chrome-stable_current_amd64.deb" \
        "command_exists google-chrome" \
        "安裝 Google Chrome"
fi

# 安裝 npm slidev
install_pkg "slidev" "npm install -g @slidev/cli" "command_exists slidev" "安裝 npm slidev"

# 安裝 helm diff
install_pkg "helm-diff" "helm plugin install https://github.com/databus23/helm-diff --verify=false" "command_exists helm && helm plugin list | grep -q -w 'diff'" "安裝 helm diff"

# 安裝 oh-my-zsh
num="$((num + 1))"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
        changed_count="$((changed_count + 1))"
        print_msg "安裝 oh-my-zsh (clean 主題)" "${GREEN}" "安裝成功"
    else
        failed_count="$((failed_count + 1))"
        print_msg "安裝 oh-my-zsh (clean 主題)" "${RED}" "安裝失敗"
    fi
else
    already_count="$((already_count + 1))"
    print_msg "安裝 oh-my-zsh (clean 主題)" "${YELLOW}" "已安裝"
fi

# 安裝 Zsh 插件
ZSH_CUSTOM=${ZSH_CUSTOM:-"$HOME/.oh-my-zsh/custom"}
declare -A zsh_plugins
zsh_plugins=(
    ["fzf-tab"]="https://github.com/Aloxaf/fzf-tab"
    ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
    ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
)

for plugin in "${!zsh_plugins[@]}"; do
    num="$((num + 1))"
    if [ ! -d "${ZSH_CUSTOM}/plugins/${plugin}" ]; then
        if git clone "${zsh_plugins[$plugin]}" "${ZSH_CUSTOM}/plugins/${plugin}" >/dev/null 2>&1; then
            changed_count="$((changed_count + 1))"
            print_msg "安裝 zsh 插件 ($plugin)" "${GREEN}" "安裝成功"
        else
            failed_count="$((failed_count + 1))"
            print_msg "安裝 zsh 插件 ($plugin)" "${RED}" "安裝失敗"
        fi
    else
        already_count="$((already_count + 1))"
        print_msg "安裝 zsh 插件 ($plugin)" "${YELLOW}" "已安裝"
    fi
done

# 設定 gke-gcloud-auth-plugin
if [[ " ${manual_install_array[@]} " =~ " gcloud " ]]; then
    install_pkg "gke-gcloud-auth-plugin" "sudo apt install -y google-cloud-sdk-gke-gcloud-auth-plugin -qq" "command_exists gke-gcloud-auth-plugin" "安裝 gke-gcloud-auth-plugin"
fi

# 設定 terraform 自動補全
if command_exists terraform; then
    terraform -install-autocomplete &>/dev/null || true
fi

# 同步 .zshrc
sync_zshrc

# 設定 .vimrc (vim option 向右單字切換)
append_to_file ":map f w" "$HOME/.vimrc" "設定 .vimrc"

# 變更預設 shell 為 zsh
num="$((num + 1))"
if [ "$SHELL" != "$(which zsh)" ]; then
    if chsh -s "$(which zsh)"; then
        changed_count="$((changed_count + 1))"
        printf "%2d _ 變更預設 shell 為 zsh : [${GREEN}設定成功${NC}]\n" "$num"
        echo -e "\n${YELLOW}請登出後重新登入以使用 zsh${NC}"
    else
        failed_count="$((failed_count + 1))"
        printf "%2d _ 變更預設 shell 為 zsh : [${RED}設定失敗${NC}]\n" "$num"
    fi
else
    already_count="$((already_count + 1))"
    printf "%2d _ 變更預設 shell 為 zsh : [${YELLOW}已設定${NC}]\n" "$num"
fi

#=========================================
# 輸出統計

printf "\n=====================================統計輸出===================================\n"
successful_steps=$((changed_count + already_count))
success_rate=$(echo "scale=2; $successful_steps/$num*100" | bc -l)
echo -e "成功 / 已有 / 失敗 / 總數：( ${GREEN}$changed_count${NC} / ${YELLOW}$already_count${NC} / ${RED}$failed_count${NC} / ${BLUE}$num${NC} )"
echo -e "整體完成率：( ${GREEN}$success_rate%${NC} )"
echo -e "\n完成！請執行以下命令來套用設定："
echo -e "${GREEN}source ~/.zshrc${NC}"
echo -e "或登出後重新登入以完全載入新環境"

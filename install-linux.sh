#!/bin/bash

#=========================================
# 參數設定
# 預設的 - 完整版 (適用於 Ubuntu/Zorin OS)
# apt_array=("zsh" "bash-completion" "wget" "curl" "git" "jq" "tree" "telnet" "build-essential" "apt-transport-https" "ca-certificates" "gnupg" "lsb-release" "software-properties-common" "python3-pip" "fzf" "dialog" "bc" "vim" "net-tools" "ipcalc" "shellcheck" "hugo" "golang-go" "nodejs" "npm" "autojump")
# snap_array=("kubectl" "helm" "terraform" "k9s" "yq" "hugo")
# snap_classic_array=("code" "docker") # 需要 --classic 的 snap 套件
# manual_install_array=("kustomize" "kubectx" "terragrunt" "awscli" "gcloud" "google-chrome" "docker-desktop")

# tuffy使用
apt_array=("zsh" "bash-completion" "wget" "curl" "git" "jq" "tree" "telnet" "build-essential" "apt-transport-https" "ca-certificates" "gnupg" "lsb-release" "software-properties-common" "python3-pip" "fzf" "dialog" "bc" "vim" "net-tools" "ipcalc" "shellcheck" "hugo" "golang-go" "nodejs" "npm" "autojump")
snap_array=("kubectl" "helm" "terraform" "k9s" "yq")
snap_classic_array=("code" "docker")
manual_install_array=("kustomize" "kubectx" "terragrunt" "awscli" "gcloud" "google-chrome")

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
var=0
num=0

#=========================================
# 顏色設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 重置颜色

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

# 安裝套件 (通用邏輯)
install_pkg() {
    local pkg_name="$1"
    local install_cmd="$2"
    local check_cmd="$3"
    local msg="$4"

    num="$((num + 1))"
    if ! eval "$check_cmd"; then
        var="$((var + 1))"
        if sudo ${install_cmd} >/dev/null 2>&1; then
            print_msg "$msg" "${GREEN}" "安裝成功"
        else
            print_msg "$msg" "${RED}" "安裝失敗"
        fi
    else
        print_msg "$msg" "${YELLOW}" "已安裝"
    fi
}

# 新增設定到檔案
append_to_file() {
    local line="$1"
    local file="$2"
    local msg="$3"
    num="$((num + 1))"
    if ! grep -qF -- "$line" "$file"; then
        var="$((var + 1))"
        echo "$line" | sudo tee -a "$file" >/dev/null
        print_msg "$msg" "${GREEN}" "設定成功"
    else
        print_msg "$msg" "${YELLOW}" "已設定"
    fi
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
var="$((var + 1))"
num="$((num + 1))"
echo -e "${num} _ 更新 apt 套件列表..."
sudo apt update -qq
printf "%2d _ 更新 apt 套件列表 : [${GREEN}更新成功${NC}]\n" "$num"

# 安裝 apt 套件
for kit in "${apt_array[@]}"; do
    var="$((var + 1))"
    num="$((num + 1))"
    if ! dpkg -l | grep -q -w "^ii  $kit"; then
        sudo apt install -y "$kit" -qq
        print_msg "安裝 apt 套件 ($kit)" "${GREEN}" "安裝成功"
    else
        print_msg "安裝 apt 套件 ($kit)" "${YELLOW}" "已安裝"
        var="$((var - 1))"
    fi
done

# 安裝 snapd（如果尚未安裝）
var="$((var + 1))"
num="$((num + 1))"
if ! command_exists snap; then
    sudo apt install -y snapd -qq
    print_msg "安裝 snapd" "${GREEN}" "安裝成功"
else
    print_msg "安裝 snapd" "${YELLOW}" "已安裝"
    var="$((var - 1))"
fi

# 安裝 snap 套件
for kit in "${snap_array[@]}"; do
    var="$((var + 1))"
    num="$((num + 1))"
    if ! snap list | grep -q -w "$kit"; then
        sudo snap install "$kit"
        print_msg "安裝 snap 套件 ($kit)" "${GREEN}" "安裝成功"
    else
        print_msg "安裝 snap 套件 ($kit)" "${YELLOW}" "已安裝"
        var="$((var - 1))"
    fi
done

# 安裝 snap 套件 (需要 --classic)
for kit in "${snap_classic_array[@]}"; do
    var="$((var + 1))"
    num="$((num + 1))"
    if ! snap list | grep -q -w "$kit"; then
        sudo snap install "$kit" --classic
        print_msg "安裝 snap 套件 --classic ($kit)" "${GREEN}" "安裝成功"
    else
        print_msg "安裝 snap 套件 --classic ($kit)" "${YELLOW}" "已安裝"
        var="$((var - 1))"
    fi
done

# 手動安裝 kustomize
if [[ " ${manual_install_array[@]} " =~ " kustomize " ]]; then
    var="$((var + 1))"
    num="$((num + 1))"
    if ! command_exists kustomize; then
        if (curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash && sudo mv kustomize /usr/local/bin/); then
            print_msg "安裝 kustomize" "${GREEN}" "安裝成功"
        else
            print_msg "安裝 kustomize" "${RED}" "安裝失敗"
        fi
    else
        print_msg "安裝 kustomize" "${YELLOW}" "已安裝"
        var="$((var - 1))"
    fi
fi

# 手動安裝 kubectx & kubens
if [[ " ${manual_install_array[@]} " =~ " kubectx " ]]; then
    install_pkg "kubectx" \
        "git clone https://github.com/ahmetb/kubectx /opt/kubectx && ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx && ln -s /opt/kubectx/kubens /usr/local/bin/kubens" \
        "command_exists kubectx" \
        "安裝 kubectx & kubens"
fi

# 手動安裝 terragrunt
if [[ " ${manual_install_array[@]} " =~ " terragrunt " ]]; then
    var="$((var + 1))"
    num="$((num + 1))"
    if ! command_exists terragrunt; then
        TERRAGRUNT_VERSION=$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | grep tag_name | cut -d '"' -f 4)
        if (wget -q "https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_linux_amd64" -O terragrunt && chmod +x terragrunt && sudo mv terragrunt /usr/local/bin/); then
            print_msg "安裝 terragrunt" "${GREEN}" "安裝成功"
        else
            print_msg "安裝 terragrunt" "${RED}" "安裝失敗"
        fi
    else
        print_msg "安裝 terragrunt" "${YELLOW}" "已安裝"
        var="$((var - 1))"
    fi
fi

# 手動安裝 AWS CLI
if [[ " ${manual_install_array[@]} " =~ " awscli " ]]; then
    install_pkg "aws" \
        "curl -s 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip' && unzip -qq awscliv2.zip && ./aws/install && rm -rf aws awscliv2.zip" \
        "command_exists aws" \
        "安裝 AWS CLI"
fi

# 手動安裝 Google Cloud SDK
if [[ " ${manual_install_array[@]} " =~ " gcloud " ]]; then
    install_pkg "gcloud" \
        "echo 'deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main' > /etc/apt/sources.list.d/google-cloud-sdk.list && curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && apt update -qq && apt install -y google-cloud-sdk -qq" \
        "command_exists gcloud" \
        "安裝 Google Cloud SDK"
fi

# 手動安裝 Google Chrome
if [[ " ${manual_install_array[@]} " =~ " google-chrome " ]]; then
    install_pkg "google-chrome" \
        "wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && apt install -y ./google-chrome-stable_current_amd64.deb -qq && rm google-chrome-stable_current_amd64.deb" \
        "command_exists google-chrome" \
        "安裝 Google Chrome"
fi

# 安裝 npm slidev
install_pkg "slidev" "npm install -g @slidev/cli" "command_exists slidev" "安裝 npm slidev"

# 安裝 helm diff
install_pkg "helm-diff" "helm plugin install https://github.com/databus23/helm-diff" "helm plugin list | grep -q -w 'diff'" "安裝 helm diff"

# 安裝 oh-my-zsh
var="$((var + 1))"
num="$((num + 1))"
if [ ! -f "$HOME/.zshrc" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    sed -i 's/ZSH_THEME=.*/ZSH_THEME="clean"/g' "$HOME"/.zshrc
    print_msg "安裝 oh-my-zsh (clean 主題)" "${GREEN}" "安裝成功"
else
    print_msg "安裝 oh-my-zsh (clean 主題)" "${YELLOW}" "已安裝"
    var="$((var - 1))"
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
    var="$((var + 1))"
    num="$((num + 1))"
    if [ ! -d "${ZSH_CUSTOM}/plugins/${plugin}" ]; then
        git clone "${zsh_plugins[$plugin]}" "${ZSH_CUSTOM}/plugins/${plugin}" >/dev/null 2>&1
        print_msg "安裝 zsh 插件 ($plugin)" "${GREEN}" "安裝成功"
    else
        print_msg "安裝 zsh 插件 ($plugin)" "${YELLOW}" "已安裝"
        var="$((var - 1))"
    fi
done

# 設定 Zsh 插件
var="$((var + 1))"
num="$((num + 1))"
ZSH_PLUGINS_LINE="plugins=(git aws fzf-tab zsh-autosuggestions zsh-syntax-highlighting autojump)"
if ! grep -q "$ZSH_PLUGINS_LINE" "$HOME"/.zshrc; then
    sed -i "s/^plugins=(.*)/${ZSH_PLUGINS_LINE}/" "$HOME"/.zshrc
    print_msg "設定 zsh 插件" "${GREEN}" "設定成功"
else
    print_msg "設定 zsh 插件" "${YELLOW}" "已設定"
    var="$((var - 1))"
fi


# 設定 gke-gcloud-auth-plugin
if [[ " ${manual_install_array[@]} " =~ " gcloud " ]]; then
    install_pkg "gke-gcloud-auth-plugin" "apt install -y google-cloud-sdk-gke-gcloud-auth-plugin -qq" "command_exists gke-gcloud-auth-plugin" "安裝 gke-gcloud-auth-plugin"
fi

# 設定 terraform 自動補全
if command_exists terraform; then
    append_to_file "autoload -U +X bashcompinit && bashcompinit" "$HOME/.zshrc" "啟用 bashcompinit for zsh"
    terraform -install-autocomplete &>/dev/null
fi

# 設定 aws 自動補全
if command_exists aws; then
    AWS_COMPLETER_PATH=$(which aws_completer 2>/dev/null || echo "/usr/local/bin/aws_completer")
    append_to_file "complete -C $AWS_COMPLETER_PATH aws" "$HOME/.bash_profile" "設定 aws 自動補全"
fi

# 設定常用 alias (kubectl)
append_to_file "alias k=\"kubectl\"" "$HOME/.bash_profile" "設定 alias (kubectl)"

# 設定常用 alias (kubens)
append_to_file "alias kns=\"kubens\"" "$HOME/.bash_profile" "設定 alias (kubens)"

# 設定常用 alias (kubectx)
append_to_file "alias ktx=\"kubectx\"" "$HOME/.bash_profile" "設定 alias (kubectx)"

# 設定 .zshrc
append_to_file "source \$HOME/.bash_profile" "$HOME/.zshrc" "設定 .zshrc"

# 設定 PS1
PS1_LINE='export PS1='\''%{$fg[$NCOLOR]%}%B%n%b%{$reset_color%}:%{$fg[blue]%}%B%c/%b%{$reset_color%} $(git_prompt_info)%(!.#.$) '\'''
append_to_file "$PS1_LINE" "$HOME/.zshrc" "設定 PS1"

# 設定 .vimrc (vim option 向右單字切換)
append_to_file ":map f w" "$HOME/.vimrc" "設定 .vimrc"

# 變更預設 shell 為 zsh
var="$((var + 1))"
num="$((num + 1))"
if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)"
    printf "%2d _ 變更預設 shell 為 zsh : [${GREEN}設定成功${NC}]\n" "$num"
    echo -e "\n${YELLOW}請登出後重新登入以使用 zsh${NC}"
else
    printf "%2d _ 變更預設 shell 為 zsh : [${YELLOW}已設定${NC}]\n" "$num"
    var="$((var - 1))"
fi

#=========================================
# 輸出統計

printf "\n=====================================統計輸出===================================\n"
success_rate=$(echo "scale=2; $var/$num*100" | bc -l)
echo -e "安裝 + 設定套件成功數 / 安裝 + 設定套件總數 / 成功率：( ${GREEN}$var${NC} ${BLUE}/ $num / ${RED}$success_rate%${NC} )"
echo -e "\n完成！請執行以下命令來套用設定："
echo -e "${GREEN}source ~/.zshrc${NC}"
echo -e "或登出後重新登入以完全載入新環境"

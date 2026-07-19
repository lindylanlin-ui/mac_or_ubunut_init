#!/bin/bash

if [[ -z "${SCRIPT_DIR:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

nowtime=$(date '+%Y/%m/%d %H:%M:%S')
log_timestamp=$(date '+%Y%m%d-%H%M%S')
num=0
changed_count=0
already_count=0
failed_count=0
repo_missing_count=0
skipped_count=0
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/install-${PROFILE_SLUG:-linux}-${log_timestamp}.log"
declare -a success_items=()
declare -a already_items=()
declare -a failed_items=()
declare -a repo_missing_items=()
declare -a skipped_items=()

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'
NC=$'\033[0m'

is_enabled() {
  [ "${1:-false}" = "true" ]
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

print_msg() {
  printf "%2d _ %s : [%s%s%s]\n" "$num" "$1" "$2" "$3" "${NC}"
}

log_line() {
  local level="$1"
  local message="$2"
  printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$message" >>"$LOG_FILE"
}

record_success() {
  success_items+=("$1")
  log_line "SUCCESS" "$1"
}

record_already() {
  already_items+=("$1")
  log_line "ALREADY" "$1"
}

record_failure() {
  failed_items+=("$1")
  log_line "FAILED" "$1 | $2"
}

record_repo_missing() {
  repo_missing_items+=("$1")
  log_line "REPO_MISSING" "$1 | $2"
}

record_skipped() {
  skipped_items+=("$1")
  log_line "SKIPPED" "$1 | $2"
}

print_error_summary() {
  local log_file="$1"
  if [ -s "$log_file" ]; then
    echo "   錯誤摘要:"
    tail -n 12 "$log_file" | sed 's/^/   /'
  fi
}

append_log_excerpt() {
  local title="$1"
  local log_file="$2"
  if [ -s "$log_file" ]; then
    {
      echo "----- ${title} -----"
      sed -n '1,20p' "$log_file"
      echo "----- ${title} (tail) -----"
      tail -n 20 "$log_file"
      echo
    } >>"$LOG_FILE"
  fi
}

repo_exists_apt() {
  local pkg="$1"
  local candidate
  candidate=$(apt-cache policy "$pkg" 2>/dev/null | awk '/Candidate:/ {print $2}')
  [ -n "$candidate" ] && [ "$candidate" != "(none)" ]
}

repo_exists_snap() {
  local pkg="$1"
  snap info "$pkg" >/dev/null 2>&1
}

run_logged_cmd() {
  local title="$1"
  local cmd="$2"
  local log_file

  log_file=$(mktemp)
  if bash -lc "$cmd" >"$log_file" 2>&1; then
    rm -f "$log_file"
    return 0
  fi

  print_error_summary "$log_file"
  append_log_excerpt "$title" "$log_file"
  rm -f "$log_file"
  return 1
}

install_pkg() {
  local install_cmd="$1"
  local check_cmd="$2"
  local msg="$3"
  local log_file

  num="$((num + 1))"
  if eval "$check_cmd"; then
    already_count="$((already_count + 1))"
    print_msg "$msg" "${YELLOW}" "已安裝"
    record_already "$msg"
  else
    log_file=$(mktemp)
    if bash -lc "$install_cmd" >"$log_file" 2>&1; then
      changed_count="$((changed_count + 1))"
      print_msg "$msg" "${GREEN}" "安裝成功"
      record_success "$msg"
    else
      failed_count="$((failed_count + 1))"
      print_msg "$msg" "${RED}" "安裝失敗"
      print_error_summary "$log_file"
      append_log_excerpt "$msg" "$log_file"
      record_failure "$msg" "安裝命令失敗，詳見 ${LOG_FILE}"
    fi
    rm -f "$log_file"
  fi
}

append_to_file() {
  local line="$1"
  local file="$2"
  local msg="$3"
  num="$((num + 1))"
  if ! grep -qF -- "$line" "$file" 2>/dev/null; then
    changed_count="$((changed_count + 1))"
    echo "$line" | sudo tee -a "$file" >/dev/null
    print_msg "$msg" "${GREEN}" "設定成功"
    record_success "$msg"
  else
    already_count="$((already_count + 1))"
    print_msg "$msg" "${YELLOW}" "已設定"
    record_already "$msg"
  fi
}

print_item_list() {
  local title="$1"
  local color="$2"
  shift 2
  local items=("$@")

  echo -e "\n${color}${title}${NC}"
  if [ "${#items[@]}" -eq 0 ]; then
    echo "  - 無"
    return
  fi

  local item
  for item in "${items[@]}"; do
    echo "  - $item"
  done
}

sync_zshrc() {
  local file="$HOME/.zshrc"
  local tmp_file
  local plugin_lines
  tmp_file=$(mktemp)

  plugin_lines="  git
  fzf-tab
  zsh-autosuggestions
  zsh-syntax-highlighting"
  if is_enabled "${ENABLE_AUTOJUMP:-false}"; then
    plugin_lines="${plugin_lines}
  autojump"
  fi

  cat >"$tmp_file" <<EOF
# =====================================================================
# Oh My Zsh 基本設定
# =====================================================================
export ZSH="\$HOME/.oh-my-zsh"
export ZSH_THEME="clean"

plugins=(
${plugin_lines}
)

source "\$ZSH/oh-my-zsh.sh"

# =====================================================================
# PATH 與常用工具
# =====================================================================
typeset -U path PATH
path=(
  "\$HOME/.local/bin"
  /usr/local/bin
  /snap/bin
  \$path
)
export PATH

if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
fi

if [ -f /usr/share/doc/fzf/examples/completion.zsh ]; then
  source /usr/share/doc/fzf/examples/completion.zsh
fi

[ -f "\$HOME/.fzf.zsh" ] && source "\$HOME/.fzf.zsh"

export LS_COLORS="\${LS_COLORS}:st=01;34:ow=01;34:tw=01;34"

# =====================================================================
# Completion
# =====================================================================
autoload -U +X bashcompinit && bashcompinit

# =====================================================================
# Prompt 與偏好設定
# =====================================================================
setopt promptsubst

HISTFILE="\$HOME/.zsh_history"
HISTSIZE=5000
SAVEHIST=5000
setopt hist_ignore_dups
setopt share_history
EOF

  num="$((num + 1))"
  if [ -f "$file" ] && cmp -s "$tmp_file" "$file"; then
    already_count="$((already_count + 1))"
    print_msg "同步 .zshrc" "${YELLOW}" "已設定"
    record_already "同步 .zshrc"
  else
    changed_count="$((changed_count + 1))"
    cp "$tmp_file" "$file"
    print_msg "同步 .zshrc" "${GREEN}" "設定成功"
    record_success "同步 .zshrc"
  fi

  rm -f "$tmp_file"
}

install_apt_packages() {
  local kit
  for kit in "${apt_prereq_array[@]}"; do
    num="$((num + 1))"
    if dpkg -l | grep -q -w "^ii  $kit"; then
      already_count="$((already_count + 1))"
      print_msg "安裝必要依賴 ($kit)" "${YELLOW}" "已安裝"
      record_already "安裝必要依賴 ($kit)"
    elif ! repo_exists_apt "$kit"; then
      repo_missing_count="$((repo_missing_count + 1))"
      print_msg "安裝必要依賴 ($kit)" "${RED}" "找不到套件來源"
      record_repo_missing "安裝必要依賴 ($kit)" "apt repository 中查無 Candidate"
    elif run_logged_cmd "安裝必要依賴 ($kit)" "sudo apt install -y \"$kit\" -qq"; then
      changed_count="$((changed_count + 1))"
      print_msg "安裝必要依賴 ($kit)" "${GREEN}" "安裝成功"
      record_success "安裝必要依賴 ($kit)"
    else
      failed_count="$((failed_count + 1))"
      print_msg "安裝必要依賴 ($kit)" "${RED}" "安裝失敗"
      record_failure "安裝必要依賴 ($kit)" "apt install 失敗"
    fi
  done

  for kit in "${apt_array[@]}"; do
    num="$((num + 1))"
    if dpkg -l | grep -q -w "^ii  $kit"; then
      already_count="$((already_count + 1))"
      print_msg "安裝 apt 套件 ($kit)" "${YELLOW}" "已安裝"
      record_already "安裝 apt 套件 ($kit)"
    elif ! repo_exists_apt "$kit"; then
      repo_missing_count="$((repo_missing_count + 1))"
      print_msg "安裝 apt 套件 ($kit)" "${RED}" "找不到套件來源"
      record_repo_missing "安裝 apt 套件 ($kit)" "apt repository 中查無 Candidate"
    elif run_logged_cmd "安裝 apt 套件 ($kit)" "sudo apt install -y \"$kit\" -qq"; then
      changed_count="$((changed_count + 1))"
      print_msg "安裝 apt 套件 ($kit)" "${GREEN}" "安裝成功"
      record_success "安裝 apt 套件 ($kit)"
    else
      failed_count="$((failed_count + 1))"
      print_msg "安裝 apt 套件 ($kit)" "${RED}" "安裝失敗"
      record_failure "安裝 apt 套件 ($kit)" "apt install 失敗"
    fi
  done
}

install_snaps() {
  local kit
  num="$((num + 1))"
  if ! command_exists snap; then
    if run_logged_cmd "安裝 snapd" "sudo apt install -y snapd -qq"; then
      changed_count="$((changed_count + 1))"
      print_msg "安裝 snapd" "${GREEN}" "安裝成功"
      record_success "安裝 snapd"
    else
      failed_count="$((failed_count + 1))"
      print_msg "安裝 snapd" "${RED}" "安裝失敗"
      record_failure "安裝 snapd" "apt install snapd 失敗"
    fi
  else
    already_count="$((already_count + 1))"
    print_msg "安裝 snapd" "${YELLOW}" "已安裝"
    record_already "安裝 snapd"
  fi

  for kit in "${snap_array[@]}"; do
    num="$((num + 1))"
    if snap list "$kit" >/dev/null 2>&1; then
      already_count="$((already_count + 1))"
      print_msg "安裝 snap 套件 ($kit)" "${YELLOW}" "已安裝"
      record_already "安裝 snap 套件 ($kit)"
    elif ! repo_exists_snap "$kit"; then
      repo_missing_count="$((repo_missing_count + 1))"
      print_msg "安裝 snap 套件 ($kit)" "${RED}" "找不到套件來源"
      record_repo_missing "安裝 snap 套件 ($kit)" "snap info 查無結果"
    elif run_logged_cmd "安裝 snap 套件 ($kit)" "sudo snap install \"$kit\""; then
      changed_count="$((changed_count + 1))"
      print_msg "安裝 snap 套件 ($kit)" "${GREEN}" "安裝成功"
      record_success "安裝 snap 套件 ($kit)"
    else
      failed_count="$((failed_count + 1))"
      print_msg "安裝 snap 套件 ($kit)" "${RED}" "安裝失敗"
      record_failure "安裝 snap 套件 ($kit)" "snap install 失敗"
    fi
  done

  for kit in "${snap_classic_array[@]}"; do
    num="$((num + 1))"
    if snap list "$kit" >/dev/null 2>&1; then
      already_count="$((already_count + 1))"
      print_msg "安裝 snap 套件 --classic ($kit)" "${YELLOW}" "已安裝"
      record_already "安裝 snap 套件 --classic ($kit)"
    elif ! repo_exists_snap "$kit"; then
      repo_missing_count="$((repo_missing_count + 1))"
      print_msg "安裝 snap 套件 --classic ($kit)" "${RED}" "找不到套件來源"
      record_repo_missing "安裝 snap 套件 --classic ($kit)" "snap info 查無結果"
    elif run_logged_cmd "安裝 snap 套件 --classic ($kit)" "sudo snap install \"$kit\" --classic"; then
      changed_count="$((changed_count + 1))"
      print_msg "安裝 snap 套件 --classic ($kit)" "${GREEN}" "安裝成功"
      record_success "安裝 snap 套件 --classic ($kit)"
    else
      failed_count="$((failed_count + 1))"
      print_msg "安裝 snap 套件 --classic ($kit)" "${RED}" "安裝失敗"
      record_failure "安裝 snap 套件 --classic ($kit)" "snap install --classic 失敗"
    fi
  done
}

install_manual_google_chrome() {
  if [[ ! " ${manual_install_array[*]} " =~ " google-chrome " ]]; then
    return
  fi

  num="$((num + 1))"
  if command_exists google-chrome; then
    already_count="$((already_count + 1))"
    print_msg "安裝 Google Chrome" "${YELLOW}" "已安裝"
    record_already "安裝 Google Chrome"
  elif ! wget --spider -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb; then
    repo_missing_count="$((repo_missing_count + 1))"
    print_msg "安裝 Google Chrome" "${RED}" "找不到套件來源"
    record_repo_missing "安裝 Google Chrome" "無法取得 Google Chrome .deb 下載網址"
  elif run_logged_cmd "安裝 Google Chrome" "wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && sudo apt install -y ./google-chrome-stable_current_amd64.deb -qq && rm -f google-chrome-stable_current_amd64.deb"; then
    changed_count="$((changed_count + 1))"
    print_msg "安裝 Google Chrome" "${GREEN}" "安裝成功"
    record_success "安裝 Google Chrome"
  else
    failed_count="$((failed_count + 1))"
    print_msg "安裝 Google Chrome" "${RED}" "安裝失敗"
    record_failure "安裝 Google Chrome" "安裝命令失敗，詳見 ${LOG_FILE}"
  fi
}

install_manual_engineer_tools() {
  if ! is_enabled "${ENABLE_ENGINEER_FEATURES:-false}"; then
    return
  fi

  if [[ " ${manual_install_array[*]} " =~ " gcloud " ]]; then
    install_pkg \
      "curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/cloud.google.gpg && echo 'deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main' | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null && sudo apt update -qq && sudo apt install -y google-cloud-sdk -qq" \
      "command_exists gcloud" \
      "安裝 Google Cloud SDK"
  fi

  if [[ " ${manual_install_array[*]} " =~ " terraform " ]]; then
    install_pkg \
      "source /etc/os-release && curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && echo \"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com \${UBUNTU_CODENAME} main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null && sudo apt update -qq && sudo apt install -y terraform -qq" \
      "command_exists terraform" \
      "安裝 Terraform"
  fi

  if [[ " ${manual_install_array[*]} " =~ " k9s " ]]; then
    install_pkg \
      "K9S_VERSION=\$(curl -fsSL https://api.github.com/repos/derailed/k9s/releases/latest | jq -r '.tag_name') && wget -q \"https://github.com/derailed/k9s/releases/download/\${K9S_VERSION}/k9s_Linux_amd64.tar.gz\" -O k9s_Linux_amd64.tar.gz && tar -xzf k9s_Linux_amd64.tar.gz k9s && chmod +x k9s && sudo mv k9s /usr/local/bin/k9s && rm -f k9s_Linux_amd64.tar.gz" \
      "command_exists k9s" \
      "安裝 k9s"
  fi

  if [[ " ${manual_install_array[*]} " =~ " kustomize " ]]; then
    install_pkg \
      "curl -s https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh | bash && sudo mv kustomize /usr/local/bin/" \
      "command_exists kustomize" \
      "安裝 kustomize"
  fi

  if [[ " ${manual_install_array[*]} " =~ " terragrunt " ]]; then
    install_pkg \
      "TERRAGRUNT_VERSION=\$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | grep tag_name | cut -d '\"' -f 4) && wget -q \"https://github.com/gruntwork-io/terragrunt/releases/download/\${TERRAGRUNT_VERSION}/terragrunt_linux_amd64\" -O terragrunt && chmod +x terragrunt && sudo mv terragrunt /usr/local/bin/" \
      "command_exists terragrunt" \
      "安裝 terragrunt"
  fi
}

print_unsupported_apps() {
  local app
  for app in "${unsupported_app_array[@]}"; do
    num="$((num + 1))"
    skipped_count="$((skipped_count + 1))"
    case "$app" in
      iterm2)
        print_msg "略過 GUI 套件 (iterm2)" "${YELLOW}" "Linux 無對應版本"
        record_skipped "略過 GUI 套件 (iterm2)" "Linux 無對應版本"
        ;;
      raycast)
        print_msg "略過 GUI 套件 (raycast)" "${YELLOW}" "Linux 無官方版本"
        record_skipped "略過 GUI 套件 (raycast)" "Linux 無官方版本"
        ;;
      openvpn-connect)
        print_msg "略過 GUI 套件 (openvpn-connect)" "${YELLOW}" "改以 openvpn + NetworkManager 套件替代"
        record_skipped "略過 GUI 套件 (openvpn-connect)" "改以 openvpn + NetworkManager 套件替代"
        ;;
      *)
        print_msg "略過 GUI 套件 ($app)" "${YELLOW}" "無對應安裝來源"
        record_skipped "略過 GUI 套件 ($app)" "無對應安裝來源"
        ;;
    esac
  done
}

install_shell_features() {
  if is_enabled "${ENABLE_SLIDEV:-false}"; then
    install_pkg "npm install -g @slidev/cli" "command_exists slidev" "安裝 npm slidev"
  fi

  if is_enabled "${ENABLE_HELM_DIFF:-false}"; then
    num="$((num + 1))"
    if command_exists helm; then
      if helm plugin list | grep -q -w 'diff'; then
        already_count="$((already_count + 1))"
        print_msg "安裝 helm diff" "${YELLOW}" "已安裝"
        record_already "安裝 helm diff"
      elif run_logged_cmd "安裝 helm diff" "helm plugin install https://github.com/databus23/helm-diff --verify=false"; then
        changed_count="$((changed_count + 1))"
        print_msg "安裝 helm diff" "${GREEN}" "安裝成功"
        record_success "安裝 helm diff"
      else
        failed_count="$((failed_count + 1))"
        print_msg "安裝 helm diff" "${RED}" "安裝失敗"
        record_failure "安裝 helm diff" "helm plugin install 失敗"
      fi
    else
      skipped_count="$((skipped_count + 1))"
      print_msg "安裝 helm diff" "${YELLOW}" "略過，未安裝 helm"
      record_skipped "安裝 helm diff" "未安裝 helm，略過 plugin 安裝"
    fi
  fi

  num="$((num + 1))"
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    if run_logged_cmd "安裝 oh-my-zsh (clean 主題)" "sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" \"\" --unattended"; then
      changed_count="$((changed_count + 1))"
      print_msg "安裝 oh-my-zsh (clean 主題)" "${GREEN}" "安裝成功"
      record_success "安裝 oh-my-zsh (clean 主題)"
    else
      failed_count="$((failed_count + 1))"
      print_msg "安裝 oh-my-zsh (clean 主題)" "${RED}" "安裝失敗"
      record_failure "安裝 oh-my-zsh (clean 主題)" "oh-my-zsh 安裝腳本執行失敗"
    fi
  else
    already_count="$((already_count + 1))"
    print_msg "安裝 oh-my-zsh (clean 主題)" "${YELLOW}" "已安裝"
    record_already "安裝 oh-my-zsh (clean 主題)"
  fi

  local plugin
  local plugin_repo
  declare -A zsh_plugins=(
    ["fzf-tab"]="https://github.com/Aloxaf/fzf-tab"
    ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
    ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
  )

  for plugin in "${!zsh_plugins[@]}"; do
    plugin_repo="${zsh_plugins[$plugin]}"
    num="$((num + 1))"
    if [ ! -d "${ZSH_CUSTOM:-"$HOME/.oh-my-zsh/custom"}/plugins/${plugin}" ]; then
      if run_logged_cmd "安裝 zsh 插件 ($plugin)" "git clone \"$plugin_repo\" \"${ZSH_CUSTOM:-"$HOME/.oh-my-zsh/custom"}/plugins/${plugin}\""; then
        changed_count="$((changed_count + 1))"
        print_msg "安裝 zsh 插件 ($plugin)" "${GREEN}" "安裝成功"
        record_success "安裝 zsh 插件 ($plugin)"
      else
        failed_count="$((failed_count + 1))"
        print_msg "安裝 zsh 插件 ($plugin)" "${RED}" "安裝失敗"
        record_failure "安裝 zsh 插件 ($plugin)" "git clone 失敗"
      fi
    else
      already_count="$((already_count + 1))"
      print_msg "安裝 zsh 插件 ($plugin)" "${YELLOW}" "已安裝"
      record_already "安裝 zsh 插件 ($plugin)"
    fi
  done

  if is_enabled "${ENABLE_ENGINEER_FEATURES:-false}" && [[ " ${manual_install_array[*]} " =~ " gcloud " ]]; then
    install_pkg "sudo apt install -y google-cloud-sdk-gke-gcloud-auth-plugin -qq" "command_exists gke-gcloud-auth-plugin" "安裝 gke-gcloud-auth-plugin"
  fi
}

finalize_shell() {
  if command_exists terraform; then
    terraform -install-autocomplete &>/dev/null || true
  fi

  sync_zshrc
  append_to_file ":map f w" "$HOME/.vimrc" "設定 .vimrc"

  num="$((num + 1))"
  if [ "$SHELL" != "$(which zsh)" ]; then
    if run_logged_cmd "變更預設 shell 為 zsh" "chsh -s \"$(which zsh)\""; then
      changed_count="$((changed_count + 1))"
      printf "%2d _ 變更預設 shell 為 zsh : [${GREEN}設定成功${NC}]\n" "$num"
      echo -e "\n${YELLOW}請登出後重新登入以使用 zsh${NC}"
      record_success "變更預設 shell 為 zsh"
    else
      failed_count="$((failed_count + 1))"
      printf "%2d _ 變更預設 shell 為 zsh : [${RED}設定失敗${NC}]\n" "$num"
      record_failure "變更預設 shell 為 zsh" "chsh 執行失敗"
    fi
  else
    already_count="$((already_count + 1))"
    printf "%2d _ 變更預設 shell 為 zsh : [${YELLOW}已設定${NC}]\n" "$num"
    record_already "變更預設 shell 為 zsh"
  fi
}

install_and_configure_yazi() {
  local source_dir="$SCRIPT_DIR/yazi"
  local config_dir="$HOME/.config/yazi"
  local file

  num="$((num + 1))"
  if ! command_exists yazi; then
    if [ ! -x "$HOME/.cargo/bin/cargo" ]; then
      if run_logged_cmd "安裝 Rust（Yazi 建置工具）" "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal"; then
        changed_count="$((changed_count + 1))"
      else
        failed_count="$((failed_count + 1))"
        print_msg "安裝 Yazi" "${RED}" "Rust 安裝失敗"
        record_failure "安裝 Yazi" "無法安裝 Rust"
        return
      fi
    fi

    if run_logged_cmd "安裝 Yazi" "\"$HOME/.cargo/bin/cargo\" install --force yazi-build"; then
      changed_count="$((changed_count + 1))"
      print_msg "安裝 Yazi" "${GREEN}" "安裝成功"
      record_success "安裝 Yazi（官方 Cargo 安裝器）"
    else
      failed_count="$((failed_count + 1))"
      print_msg "安裝 Yazi" "${RED}" "安裝失敗"
      record_failure "安裝 Yazi" "cargo install yazi-build 失敗"
      return
    fi
  else
    already_count="$((already_count + 1))"
    print_msg "安裝 Yazi" "${YELLOW}" "已安裝"
    record_already "安裝 Yazi"
  fi

  mkdir -p "$config_dir"
  for file in yazi.linux.toml keymap.toml theme.toml init.lua shell.zsh; do
    cp "$source_dir/$file" "$config_dir/${file/yazi.linux.toml/yazi.toml}"
  done
  append_to_file '[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"' "$HOME/.zshrc" "設定 Rust PATH（Yazi）"
  append_to_file '[ -f "$HOME/.config/yazi/shell.zsh" ] && source "$HOME/.config/yazi/shell.zsh"' "$HOME/.zshrc" "啟用 Yazi 離開後切換目錄"
  changed_count="$((changed_count + 1))"
  print_msg "設定 Yazi" "${GREEN}" "設定檔已同步"
  record_success "設定 Yazi（主題、快捷鍵、cwd wrapper）"
}

print_summary() {
  local successful_steps
  local success_rate
  successful_steps=$((changed_count + already_count + skipped_count))
  success_rate=$(echo "scale=2; $successful_steps/$num*100" | bc -l)
  printf "\n=====================================統計輸出===================================\n"
  echo -e "成功 / 已有 / 略過 / 找不到來源 / 失敗 / 總數：( ${GREEN}$changed_count${NC} / ${YELLOW}$already_count${NC} / ${BLUE}$skipped_count${NC} / ${YELLOW}$repo_missing_count${NC} / ${RED}$failed_count${NC} / ${BLUE}$num${NC} )"
  echo -e "整體完成率：( ${GREEN}$success_rate%${NC} )"
  echo -e "log 檔案：( ${GREEN}$LOG_FILE${NC} )"

  print_item_list "本次安裝成功" "${GREEN}" "${success_items[@]}"
  print_item_list "原本已安裝或已設定" "${YELLOW}" "${already_items[@]}"
  print_item_list "略過項目" "${BLUE}" "${skipped_items[@]}"
  print_item_list "找不到套件來源" "${YELLOW}" "${repo_missing_items[@]}"
  print_item_list "安裝或設定失敗" "${RED}" "${failed_items[@]}"

  {
    echo
    echo "==================== 最終摘要 ===================="
    echo "成功: ${changed_count}"
    echo "已有: ${already_count}"
    echo "略過: ${skipped_count}"
    echo "找不到來源: ${repo_missing_count}"
    echo "失敗: ${failed_count}"
    echo "總數: ${num}"
    echo "完成率: ${success_rate}%"
    echo
    echo "[成功]"
    printf ' - %s\n' "${success_items[@]:-無}"
    echo "[已有]"
    printf ' - %s\n' "${already_items[@]:-無}"
    echo "[略過]"
    printf ' - %s\n' "${skipped_items[@]:-無}"
    echo "[找不到來源]"
    printf ' - %s\n' "${repo_missing_items[@]:-無}"
    echo "[失敗]"
    printf ' - %s\n' "${failed_items[@]:-無}"
  } >>"$LOG_FILE"

  log_line "INFO" "腳本執行完成"
  echo -e "\n完成！請執行以下命令來套用設定："
  echo -e "${GREEN}source ~/.zshrc${NC}"
  echo -e "或登出後重新登入以完全載入新環境"
}

run_linux_install() {
  echo -e "============================== ${PROFILE_TITLE} 腳本 =============================="
  echo -e "${PROFILE_DESCRIPTION}"
  echo -e "腳本開始時間 ${nowtime}"
  mkdir -p "$LOG_DIR"
  : >"$LOG_FILE"
  log_line "INFO" "腳本開始執行"
  log_line "INFO" "log file: ${LOG_FILE}"
  echo -e "安裝記錄檔: ${LOG_FILE}"

  if [[ $EUID -ne 0 ]] && ! sudo -v; then
    echo -e "${RED}此腳本需要 sudo 權限，請確認您有 sudo 權限${NC}"
    log_line "ERROR" "缺少 sudo 權限，腳本終止"
    exit 1
  fi

  num="$((num + 1))"
  echo -e "${num} _ 更新 apt 套件列表..."
  if run_logged_cmd "更新 apt 套件列表" "sudo apt update -qq"; then
    changed_count="$((changed_count + 1))"
    printf "%2d _ 更新 apt 套件列表 : [${GREEN}更新成功${NC}]\n" "$num"
    record_success "更新 apt 套件列表"
  else
    failed_count="$((failed_count + 1))"
    printf "%2d _ 更新 apt 套件列表 : [${RED}更新失敗${NC}]\n" "$num"
    record_failure "更新 apt 套件列表" "apt update 失敗"
  fi

  install_apt_packages
  install_snaps
  install_manual_engineer_tools
  install_manual_google_chrome
  print_unsupported_apps
  install_shell_features
  finalize_shell
  install_and_configure_yazi
  print_summary
}

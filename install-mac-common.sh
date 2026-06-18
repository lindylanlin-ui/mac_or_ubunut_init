#!/bin/bash

if [[ -z "${SCRIPT_DIR:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

nowtime=$(date '+%Y/%m/%d %H:%M:%S')
log_timestamp=$(date '+%Y%m%d-%H%M%S')
success_count=0
num=0
already_count=0
failed_count=0
skipped_count=0
repo_missing_count=0
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/install-${PROFILE_SLUG:-mac}-${log_timestamp}.log"
declare -a success_items=()
declare -a already_items=()
declare -a failed_items=()
declare -a skipped_items=()
declare -a repo_missing_items=()

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'
NC=$'\033[0m'

is_enabled() {
  [ "${1:-false}" = "true" ]
}

print_msg() {
  printf "%2d _ %s : [%s%s%s]\n" "$num" "$1" "$2" "$3" "${NC}"
}

log_line() {
  printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2" >>"$LOG_FILE"
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

record_skipped() {
  skipped_items+=("$1")
  log_line "SKIPPED" "$1 | $2"
}

record_repo_missing() {
  repo_missing_items+=("$1")
  log_line "REPO_MISSING" "$1 | $2"
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

app_exists_for_cask() {
  local cask="$1"

  case "$cask" in
    google-chrome)
      [ -d "/Applications/Google Chrome.app" ]
      ;;
    iterm2)
      [ -d "/Applications/iTerm.app" ]
      ;;
    visual-studio-code)
      [ -d "/Applications/Visual Studio Code.app" ]
      ;;
    raycast)
      [ -d "/Applications/Raycast.app" ]
      ;;
    openvpn-connect)
      [ -d "/Applications/OpenVPN Connect.app" ] || [ -d "/Applications/OpenVPN Connect/OpenVPN Connect.app" ]
      ;;
    drawio)
      [ -d "/Applications/draw.io.app" ] || [ -d "/Applications/draw.io.desktop.app" ]
      ;;
    docker)
      [ -d "/Applications/Docker.app" ]
      ;;
    notion)
      [ -d "/Applications/Notion.app" ]
      ;;
    google-cloud-sdk)
      command -v gcloud >/dev/null 2>&1
      ;;
    *)
      return 1
      ;;
  esac
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

append_line_if_missing() {
  local line="$1"
  local file="$2"
  local msg="$3"

  success_count="$((success_count + 1))"
  num="$((num + 1))"
  if ! grep -qF -- "$line" "$file" 2>/dev/null; then
    echo "$line" >>"$file"
    print_msg "$msg" "${GREEN}" "設定成功"
    record_success "$msg"
  else
    print_msg "$msg" "${YELLOW}" "已設定"
    record_already "$msg"
    already_count="$((already_count + 1))"
    success_count="$((success_count - 1))"
  fi
}

remove_line_if_present() {
  local line="$1"
  local file="$2"
  local msg="$3"
  local tmp_file

  success_count="$((success_count + 1))"
  num="$((num + 1))"
  if grep -qF -- "$line" "$file" 2>/dev/null; then
    tmp_file=$(mktemp)
    grep -vF -- "$line" "$file" >"$tmp_file"
    mv "$tmp_file" "$file"
    print_msg "$msg" "${GREEN}" "修正成功"
    record_success "$msg"
  else
    print_msg "$msg" "${YELLOW}" "無需修正"
    record_already "$msg"
    already_count="$((already_count + 1))"
    success_count="$((success_count - 1))"
  fi
}

ensure_homebrew_owner() {
  local path
  for path in /opt/homebrew /opt/homebrew/share/zsh /opt/homebrew/share/zsh/site-functions /opt/homebrew/var/homebrew/locks; do
    if [ -e "$path" ] && [ ! -O "$path" ] && sudo -n true 2>/dev/null; then
      sudo chown -R "$(whoami)" "$path"
    fi
  done
}

detect_homebrew_prefix() {
  if [ -x /opt/homebrew/bin/brew ]; then
    printf '/opt/homebrew'
  elif [ -x /usr/local/bin/brew ]; then
    printf '/usr/local'
  elif [ "$(uname -m)" = "arm64" ]; then
    printf '/opt/homebrew'
  else
    printf '/usr/local'
  fi
}

load_homebrew_env() {
  local brew_prefix="$1"

  if [ -x "${brew_prefix}/bin/brew" ]; then
    eval "$("${brew_prefix}/bin/brew" shellenv)"
    return 0
  fi

  return 1
}

require_homebrew() {
  if command -v brew >/dev/null 2>&1 || load_homebrew_env "$(detect_homebrew_prefix)"; then
    return 0
  fi

  success_count="$((success_count + 1))"
  num="$((num + 1))"
  print_msg "確認 Homebrew 環境" "${RED}" "找不到 brew"
  record_failure "確認 Homebrew 環境" "Homebrew 未安裝成功或 PATH 尚未載入"
  failed_count="$((failed_count + 1))"
  success_count="$((success_count - 1))"
  return 1
}

install_homebrew_if_needed() {
  local brew_prefix
  local brew_shellenv_line

  success_count="$((success_count + 1))"
  num="$((num + 1))"
  brew_prefix="$(detect_homebrew_prefix)"
  if [ "$brew_prefix" = "/opt/homebrew" ]; then
    ensure_homebrew_owner
  fi

  if ! command -v brew >/dev/null 2>&1; then
    brew_shellenv_line="eval \"\$(${brew_prefix}/bin/brew shellenv)\""
    append_line_if_missing "$brew_shellenv_line" "$HOME/.zprofile" "設定 Homebrew PATH (.zprofile)"
    append_line_if_missing "$brew_shellenv_line" "$HOME/.bash_profile" "設定 Homebrew PATH (.bash_profile)"
    if run_logged_cmd "安裝 Homebrew" "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""; then
      if load_homebrew_env "$brew_prefix"; then
        print_msg "安裝 Homebrew" "${GREEN}" "安裝成功"
        record_success "安裝 Homebrew"
      else
        print_msg "安裝 Homebrew" "${RED}" "安裝後找不到 brew"
        record_failure "安裝 Homebrew" "brew shellenv 載入失敗"
        failed_count="$((failed_count + 1))"
        success_count="$((success_count - 1))"
      fi
    else
      print_msg "安裝 Homebrew" "${RED}" "安裝失敗"
      record_failure "安裝 Homebrew" "Homebrew install script 執行失敗"
      failed_count="$((failed_count + 1))"
      success_count="$((success_count - 1))"
    fi
  else
    load_homebrew_env "$brew_prefix"
    print_msg "安裝 Homebrew" "${YELLOW}" "已安裝"
    record_already "安裝 Homebrew"
    already_count="$((already_count + 1))"
    success_count="$((success_count - 1))"
  fi
}

install_taps() {
  local kit
  for kit in "${brew_tap_array[@]}"; do
    success_count="$((success_count + 1))"
    num="$((num + 1))"
    if brew tap | grep -w "$kit" >/dev/null 2>&1; then
      print_msg "安裝 Homebrew tap ($kit)" "${YELLOW}" "已安裝"
      record_already "安裝 Homebrew tap ($kit)"
      already_count="$((already_count + 1))"
      success_count="$((success_count - 1))"
    elif brew tap-info "$kit" >/dev/null 2>&1 || [[ "$kit" == */tap ]]; then
      if run_logged_cmd "安裝 Homebrew tap ($kit)" "brew tap \"$kit\""; then
        print_msg "安裝 Homebrew tap ($kit)" "${GREEN}" "安裝成功"
        record_success "安裝 Homebrew tap ($kit)"
      else
        print_msg "安裝 Homebrew tap ($kit)" "${RED}" "安裝失敗"
        record_failure "安裝 Homebrew tap ($kit)" "brew tap 失敗"
        failed_count="$((failed_count + 1))"
        success_count="$((success_count - 1))"
      fi
    else
      print_msg "安裝 Homebrew tap ($kit)" "${RED}" "找不到套件來源"
      record_repo_missing "安裝 Homebrew tap ($kit)" "brew tap-info 查無結果"
      repo_missing_count="$((repo_missing_count + 1))"
      success_count="$((success_count - 1))"
    fi
  done
}

install_formulas() {
  local kit
  local kit_name

  for kit in "${brew_array[@]}"; do
    success_count="$((success_count + 1))"
    num="$((num + 1))"
    kit_name="${kit##*/}"
    if brew list | grep -w "$kit_name" >/dev/null 2>&1; then
      print_msg "安裝 Homebrew 套件 ($kit)" "${YELLOW}" "已安裝"
      record_already "安裝 Homebrew 套件 ($kit)"
      already_count="$((already_count + 1))"
      success_count="$((success_count - 1))"
    elif brew info "$kit" >/dev/null 2>&1; then
      if run_logged_cmd "安裝 Homebrew 套件 ($kit)" "brew install \"$kit\""; then
        print_msg "安裝 Homebrew 套件 ($kit)" "${GREEN}" "安裝成功"
        record_success "安裝 Homebrew 套件 ($kit)"
      else
        print_msg "安裝 Homebrew 套件 ($kit)" "${RED}" "安裝失敗"
        record_failure "安裝 Homebrew 套件 ($kit)" "brew install 失敗"
        failed_count="$((failed_count + 1))"
        success_count="$((success_count - 1))"
      fi
    else
      print_msg "安裝 Homebrew 套件 ($kit)" "${RED}" "找不到套件來源"
      record_repo_missing "安裝 Homebrew 套件 ($kit)" "brew info 查無結果"
      repo_missing_count="$((repo_missing_count + 1))"
      success_count="$((success_count - 1))"
    fi
  done
}

install_casks() {
  local kit
  local check_name

  for kit in "${brew_cask[@]}"; do
    success_count="$((success_count + 1))"
    num="$((num + 1))"
    check_name="$kit"
    if [ "$kit" = "google-cloud-sdk" ]; then
      check_name="gcloud-cli"
    fi

    if brew list --cask | grep -w "$check_name" >/dev/null 2>&1; then
      print_msg "安裝 Homebrew 視窗程式 ($kit)" "${YELLOW}" "已安裝"
      record_already "安裝 Homebrew 視窗程式 ($kit)"
      already_count="$((already_count + 1))"
      success_count="$((success_count - 1))"
    elif app_exists_for_cask "$kit"; then
      print_msg "安裝 Homebrew 視窗程式 ($kit)" "${YELLOW}" "已存在於 Applications"
      record_already "安裝 Homebrew 視窗程式 ($kit)"
      already_count="$((already_count + 1))"
      success_count="$((success_count - 1))"
    elif brew info --cask "$kit" >/dev/null 2>&1; then
      if run_logged_cmd "安裝 Homebrew 視窗程式 ($kit)" "brew install --cask \"$kit\""; then
        print_msg "安裝 Homebrew 視窗程式 ($kit)" "${GREEN}" "安裝成功"
        record_success "安裝 Homebrew 視窗程式 ($kit)"
      else
        print_msg "安裝 Homebrew 視窗程式 ($kit)" "${RED}" "安裝失敗"
        record_failure "安裝 Homebrew 視窗程式 ($kit)" "brew install --cask 失敗"
        failed_count="$((failed_count + 1))"
        success_count="$((success_count - 1))"
      fi
    else
      print_msg "安裝 Homebrew 視窗程式 ($kit)" "${RED}" "找不到套件來源"
      record_repo_missing "安裝 Homebrew 視窗程式 ($kit)" "brew info --cask 查無結果"
      repo_missing_count="$((repo_missing_count + 1))"
      success_count="$((success_count - 1))"
    fi
  done
}

configure_oh_my_zsh_plugins() {
  local plugins=("git")
  local plugin_line
  local tmp_file

  if is_enabled "${ENABLE_FZF_TAB:-false}"; then
    plugins+=("fzf-tab")
  fi
  if is_enabled "${ENABLE_ZSH_AUTOSUGGESTIONS:-false}"; then
    plugins+=("zsh-autosuggestions")
  fi
  if is_enabled "${ENABLE_ZSH_SYNTAX_HIGHLIGHTING:-false}"; then
    plugins+=("zsh-syntax-highlighting")
  fi
  if is_enabled "${ENABLE_AUTOJUMP:-false}"; then
    plugins+=("autojump")
  fi

  plugin_line="plugins=(${plugins[*]})"
  if grep -q '^plugins=' "$HOME/.zshrc" 2>/dev/null; then
    tmp_file=$(mktemp)
    awk -v plugin_line="$plugin_line" '
      BEGIN { replacing = 0 }
      /^plugins=\(/ {
        print plugin_line
        if ($0 !~ /\)[[:space:]]*$/) {
          replacing = 1
        }
        next
      }
      replacing {
        if ($0 ~ /\)[[:space:]]*$/) {
          replacing = 0
        }
        next
      }
      { print }
    ' "$HOME/.zshrc" >"$tmp_file"
    mv "$tmp_file" "$HOME/.zshrc"
  else
    echo "$plugin_line" >>"$HOME/.zshrc"
  fi
}

install_git_plugin() {
  local plugin_name="$1"
  local repo="$2"
  local plugin_dir="${ZSH_CUSTOM:-"$HOME/.oh-my-zsh/custom"}/plugins/${plugin_name}"

  success_count="$((success_count + 1))"
  num="$((num + 1))"
  if [ -d "$plugin_dir" ]; then
    configure_oh_my_zsh_plugins
    print_msg "安裝 ${plugin_name}" "${YELLOW}" "已安裝"
    record_already "安裝 ${plugin_name}"
    already_count="$((already_count + 1))"
    success_count="$((success_count - 1))"
    return
  fi

  if run_logged_cmd "安裝 ${plugin_name}" "git clone \"${repo}\" \"${plugin_dir}\""; then
    configure_oh_my_zsh_plugins
    print_msg "安裝 ${plugin_name}" "${GREEN}" "安裝成功"
    record_success "安裝 ${plugin_name}"
  else
    print_msg "安裝 ${plugin_name}" "${RED}" "安裝失敗"
    record_failure "安裝 ${plugin_name}" "git clone 失敗"
    failed_count="$((failed_count + 1))"
    success_count="$((success_count - 1))"
  fi
}

install_optional_feature() {
  local msg="$1"
  local check_cmd="$2"
  local install_cmd="$3"
  local missing_reason="$4"

  success_count="$((success_count + 1))"
  num="$((num + 1))"
  if eval "$check_cmd"; then
    print_msg "$msg" "${YELLOW}" "已安裝"
    record_already "$msg"
    already_count="$((already_count + 1))"
    success_count="$((success_count - 1))"
  elif eval "$missing_reason"; then
    print_msg "$msg" "${YELLOW}" "略過"
    record_skipped "$msg" "缺少前置工具"
    skipped_count="$((skipped_count + 1))"
    success_count="$((success_count - 1))"
  elif run_logged_cmd "$msg" "$install_cmd"; then
    print_msg "$msg" "${GREEN}" "安裝成功"
    record_success "$msg"
  else
    print_msg "$msg" "${RED}" "安裝失敗"
    record_failure "$msg" "安裝命令失敗"
    failed_count="$((failed_count + 1))"
    success_count="$((success_count - 1))"
  fi
}

install_oh_my_zsh_if_enabled() {
  if ! is_enabled "${ENABLE_OH_MY_ZSH:-false}"; then
    return
  fi

  success_count="$((success_count + 1))"
  num="$((num + 1))"
  if [ -f "$HOME/.zshrc" ]; then
    print_msg "安裝 oh-my-zsh (clean 主題)" "${YELLOW}" "已安裝"
    record_already "安裝 oh-my-zsh (clean 主題)"
    already_count="$((already_count + 1))"
    success_count="$((success_count - 1))"
  elif run_logged_cmd "安裝 oh-my-zsh (clean 主題)" "sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""; then
    sed -i -e 's/ZSH_THEME=.*/ZSH_THEME="clean"/g' "$HOME/.zshrc"
    configure_oh_my_zsh_plugins
    print_msg "安裝 oh-my-zsh (clean 主題)" "${GREEN}" "安裝成功"
    record_success "安裝 oh-my-zsh (clean 主題)"
  else
    print_msg "安裝 oh-my-zsh (clean 主題)" "${RED}" "安裝失敗"
    record_failure "安裝 oh-my-zsh (clean 主題)" "oh-my-zsh 安裝腳本執行失敗"
    failed_count="$((failed_count + 1))"
    success_count="$((success_count - 1))"
  fi
}

configure_autojump() {
  if ! is_enabled "${ENABLE_AUTOJUMP:-false}"; then
    return
  fi

  success_count="$((success_count + 1))"
  num="$((num + 1))"
  if grep -q "autojump" "$HOME/.zshrc" 2>/dev/null; then
    print_msg "設定 autojump" "${YELLOW}" "已設定"
    record_already "設定 autojump"
    already_count="$((already_count + 1))"
    success_count="$((success_count - 1))"
  else
    configure_oh_my_zsh_plugins
    print_msg "設定 autojump" "${GREEN}" "設定成功"
    record_success "設定 autojump"
  fi
}

configure_terraform_autocomplete() {
  if ! is_enabled "${ENABLE_TERRAFORM_AUTOCOMPLETE:-false}"; then
    return
  fi

  success_count="$((success_count + 1))"
  num="$((num + 1))"
  if grep -q "complete -o nospace -C /usr/local/bin/terraform terraform" "$HOME/.zshrc" 2>/dev/null || \
     grep -q 'complete -o nospace -C "$(command -v terraform)" terraform' "$HOME/.zshrc" 2>/dev/null; then
    print_msg "設定 terraform 自動補全" "${YELLOW}" "已設定"
    record_already "設定 terraform 自動補全"
    already_count="$((already_count + 1))"
    success_count="$((success_count - 1))"
  elif command -v terraform >/dev/null 2>&1; then
    append_line_if_missing 'complete -o nospace -C "$(command -v terraform)" terraform' "$HOME/.zshrc" "設定 terraform 自動補全"
  else
    print_msg "設定 terraform 自動補全" "${YELLOW}" "略過，未安裝 terraform"
    record_skipped "設定 terraform 自動補全" "未安裝 terraform"
    skipped_count="$((skipped_count + 1))"
    success_count="$((success_count - 1))"
  fi
}

configure_vault_autocomplete() {
  if ! is_enabled "${ENABLE_VAULT_AUTOCOMPLETE:-false}"; then
    return
  fi

  success_count="$((success_count + 1))"
  num="$((num + 1))"
  if grep -q 'complete -C "$(command -v vault)" vault' "$HOME/.zshrc" 2>/dev/null || \
     grep -q "complete -C /opt/homebrew/bin/vault vault" "$HOME/.zshrc" 2>/dev/null || \
     grep -q "complete -C /usr/local/bin/vault vault" "$HOME/.zshrc" 2>/dev/null; then
    print_msg "設定 vault 自動補全" "${YELLOW}" "已設定"
    record_already "設定 vault 自動補全"
    already_count="$((already_count + 1))"
    success_count="$((success_count - 1))"
  elif command -v vault >/dev/null 2>&1; then
    append_line_if_missing 'complete -C "$(command -v vault)" vault' "$HOME/.zshrc" "設定 vault 自動補全"
  else
    print_msg "設定 vault 自動補全" "${YELLOW}" "略過，未安裝 vault"
    record_skipped "設定 vault 自動補全" "未安裝 vault"
    skipped_count="$((skipped_count + 1))"
    success_count="$((success_count - 1))"
  fi
}

configure_aws_autocomplete() {
  if ! is_enabled "${ENABLE_AWS_AUTOCOMPLETE:-false}"; then
    return
  fi

  if [ -x /opt/homebrew/bin/aws_completer ] || [ -x /usr/local/bin/aws_completer ]; then
    append_line_if_missing 'complete -C "$(command -v aws_completer)" aws' "$HOME/.zshrc" "設定 aws 自動補全"
  else
    success_count="$((success_count + 1))"
    num="$((num + 1))"
    print_msg "設定 aws 自動補全" "${YELLOW}" "略過，未安裝 awscli"
    record_skipped "設定 aws 自動補全" "未安裝 awscli"
    skipped_count="$((skipped_count + 1))"
    success_count="$((success_count - 1))"
  fi
}

configure_k8s_aliases() {
  if ! is_enabled "${ENABLE_K8S_ALIASES:-false}"; then
    return
  fi

  append_line_if_missing 'alias k="kubectl"' "$HOME/.zshrc" "設定 alias (kubectl)"
  append_line_if_missing 'alias kns="kubens"' "$HOME/.zshrc" "設定 alias (kubens)"
  append_line_if_missing 'alias ktx="kubectx"' "$HOME/.zshrc" "設定 alias (kubectx)"
}

cleanup_zshrc_bash_profile_source() {
  remove_line_if_present 'source $HOME/.bash_profile' "$HOME/.zshrc" "移除 .zshrc 載入 .bash_profile"
  remove_line_if_present 'source ~/.bash_profile' "$HOME/.zshrc" "移除 .zshrc 載入 ~/.bash_profile"
}

configure_ps1() {
  local ps1_line='export PS1='\''%{$fg[$NCOLOR]%}%B%n%b%{$reset_color%}:%{$fg[blue]%}%B%c/%b%{$reset_color%} $(git_prompt_info)%(!.#.$) '\'''

  if ! is_enabled "${ENABLE_PS1:-false}"; then
    return
  fi

  success_count="$((success_count + 1))"
  num="$((num + 1))"
  if grep -Eq '^(export )?PS1=' "$HOME/.zshrc" 2>/dev/null; then
    print_msg "設定 PS1" "${YELLOW}" "已設定"
    record_already "設定 PS1"
    already_count="$((already_count + 1))"
    success_count="$((success_count - 1))"
  else
    echo "$ps1_line" >>"$HOME/.zshrc"
    print_msg "設定 PS1" "${GREEN}" "設定成功"
    record_success "設定 PS1"
  fi
}

configure_vimrc() {
  if ! is_enabled "${ENABLE_VIMRC:-false}"; then
    return
  fi

  append_line_if_missing ":map f w" "$HOME/.vimrc" "設定 .vimrc"
}

configure_iterm2_profile() {
  local profile_dir="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
  local profile_file="$SCRIPT_DIR/new_tuffy_iterm2_setting.json"
  local profile_guid

  if ! is_enabled "${ENABLE_ITERM2_PROFILE:-false}"; then
    return
  fi

  success_count="$((success_count + 1))"
  num="$((num + 1))"

  if [ ! -f "$profile_file" ]; then
    print_msg "設定 iTerm2 Profile" "${RED}" "設定檔不存在"
    record_failure "設定 iTerm2 Profile" "new_tuffy_iterm2_setting.json 不存在"
    failed_count="$((failed_count + 1))"
    success_count="$((success_count - 1))"
    return
  fi

  profile_guid=$(grep -o '"Guid"[[:space:]]*:[[:space:]]*"[^"]*"' "$profile_file" | cut -d'"' -f4)
  mkdir -p "$profile_dir"
  if ! diff "$profile_file" "$profile_dir/$(basename "$profile_file")" >/dev/null 2>&1; then
    cp "$profile_file" "$profile_dir/"
    defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "$profile_guid"
    defaults write com.googlecode.iterm2 "Default Bookmark Guid For New Windows" -string "$profile_guid"
    killall iTerm2 >/dev/null 2>&1 || true
    print_msg "設定 iTerm2 Profile" "${GREEN}" "已複製設定檔"
    record_success "設定 iTerm2 Profile"
  else
    print_msg "設定 iTerm2 Profile" "${YELLOW}" "已存在相同設定檔"
    record_already "設定 iTerm2 Profile"
    already_count="$((already_count + 1))"
    success_count="$((success_count - 1))"
  fi
}

install_engineer_features() {
  if is_enabled "${ENABLE_KUBECOLOR:-false}"; then
    success_count="$((success_count + 1))"
    num="$((num + 1))"
    if command -v kubecolor >/dev/null 2>&1; then
      grep -qF -- 'alias kubectl="kubecolor"' "$HOME/.zshrc" 2>/dev/null || echo 'alias kubectl="kubecolor"' >>"$HOME/.zshrc"
      print_msg "安裝 kubecolor + 設定 alias" "${YELLOW}" "已安裝"
      record_already "安裝 kubecolor + 設定 alias"
      already_count="$((already_count + 1))"
      success_count="$((success_count - 1))"
    elif brew info hidetatz/tap/kubecolor >/dev/null 2>&1; then
      if run_logged_cmd "安裝 kubecolor + 設定 alias" "brew install hidetatz/tap/kubecolor"; then
        append_line_if_missing 'alias kubectl="kubecolor"' "$HOME/.zshrc" "設定 alias (kubecolor)"
        print_msg "安裝 kubecolor + 設定 alias" "${GREEN}" "安裝成功"
        record_success "安裝 kubecolor + 設定 alias"
      else
        print_msg "安裝 kubecolor + 設定 alias" "${RED}" "安裝失敗"
        record_failure "安裝 kubecolor + 設定 alias" "brew install 失敗"
        failed_count="$((failed_count + 1))"
        success_count="$((success_count - 1))"
      fi
    else
      print_msg "安裝 kubecolor + 設定 alias" "${RED}" "找不到套件來源"
      record_repo_missing "安裝 kubecolor + 設定 alias" "brew info 查無結果"
      repo_missing_count="$((repo_missing_count + 1))"
      success_count="$((success_count - 1))"
    fi
  fi

  if is_enabled "${ENABLE_SLIDEV:-false}"; then
    install_optional_feature "安裝 npm slidev" \
      "command -v slidev >/dev/null 2>&1" \
      "npm install -g @slidev/cli" \
      "false"
  fi

  if is_enabled "${ENABLE_HELM_DIFF:-false}"; then
    install_optional_feature "安裝 helm diff" \
      "helm diff version >/dev/null 2>&1" \
      "helm plugin install https://github.com/databus23/helm-diff --verify=false" \
      "! command -v helm >/dev/null 2>&1"
  fi

  if is_enabled "${ENABLE_GKE_GCLOUD_AUTH_PLUGIN:-false}"; then
    success_count="$((success_count + 1))"
    num="$((num + 1))"
    if ! command -v gcloud >/dev/null 2>&1; then
      print_msg "安裝 gke-gcloud-auth-plugin" "${YELLOW}" "略過，未安裝 gcloud"
      record_skipped "安裝 gke-gcloud-auth-plugin" "未安裝 gcloud"
      skipped_count="$((skipped_count + 1))"
      success_count="$((success_count - 1))"
    elif gcloud components list --filter="gke-gcloud-auth-plugin" --format="value(state.name)" 2>/dev/null | grep -q "Not Installed"; then
      if run_logged_cmd "安裝 gke-gcloud-auth-plugin" "echo 'Y' | gcloud components install gke-gcloud-auth-plugin"; then
        print_msg "安裝 gke-gcloud-auth-plugin" "${GREEN}" "安裝成功或已是最新版本"
        record_success "安裝 gke-gcloud-auth-plugin"
      else
        print_msg "安裝 gke-gcloud-auth-plugin" "${RED}" "安裝失敗"
        record_failure "安裝 gke-gcloud-auth-plugin" "gcloud components install 失敗"
        failed_count="$((failed_count + 1))"
        success_count="$((success_count - 1))"
      fi
    else
      print_msg "安裝 gke-gcloud-auth-plugin" "${YELLOW}" "已安裝"
      record_already "安裝 gke-gcloud-auth-plugin"
      already_count="$((already_count + 1))"
      success_count="$((success_count - 1))"
    fi
  fi
}

print_summary() {
  local success_rate
  success_rate=$(echo -e "scale=2; ($success_count+$already_count+$skipped_count)/$num*100" | bc -l)

  printf "\n=====================================統計輸出===================================\n"
  echo -e "成功 / 已有 / 略過 / 找不到來源 / 失敗 / 總數：( ${GREEN}$success_count${NC} / ${YELLOW}$already_count${NC} / ${BLUE}$skipped_count${NC} / ${YELLOW}$repo_missing_count${NC} / ${RED}$failed_count${NC} / ${BLUE}$num${NC} )"
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
    echo "成功: ${success_count}"
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
}

run_mac_install() {
  echo -e "============================== ${PROFILE_TITLE} 腳本 =============================="
  echo -e "${PROFILE_DESCRIPTION}"
  echo -e "腳本開始時間 ${nowtime}"
  mkdir -p "$LOG_DIR"
  : >"$LOG_FILE"
  log_line "INFO" "腳本開始執行"
  log_line "INFO" "log file: ${LOG_FILE}"
  echo -e "安裝記錄檔: ${LOG_FILE}"

  install_homebrew_if_needed
  if ! require_homebrew; then
    print_summary
    return 1
  fi

  install_taps
  install_formulas
  install_casks

  install_engineer_features
  install_oh_my_zsh_if_enabled

  if is_enabled "${ENABLE_FZF_TAB:-false}"; then
    install_git_plugin "fzf-tab" "https://github.com/Aloxaf/fzf-tab"
  fi
  if is_enabled "${ENABLE_ZSH_AUTOSUGGESTIONS:-false}"; then
    install_git_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
  fi
  if is_enabled "${ENABLE_ZSH_SYNTAX_HIGHLIGHTING:-false}"; then
    install_git_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"
  fi

  configure_autojump
  configure_terraform_autocomplete
  configure_vault_autocomplete
  configure_aws_autocomplete
  configure_k8s_aliases
  cleanup_zshrc_bash_profile_source
  configure_ps1
  configure_vimrc
  configure_iterm2_profile
  print_summary
}

#!/bin/bash

# 共用的互動式選單工具。需要 Bash 3.2 相容，因此不使用 nameref 或 associative array。

command_exists_interactive() {
  command -v "$1" >/dev/null 2>&1
}

prepare_interactive_menu() {
  if [ -n "${LOG_DIR:-}" ] && [ -n "${LOG_FILE:-}" ]; then
    mkdir -p "$LOG_DIR"
    : >"$LOG_FILE"
  fi

  if command_exists_interactive dialog; then
    return 0
  fi

  echo "首次使用互動式安裝，需要先安裝終端機選單工具 dialog。"
  if [ "${INTERACTIVE_PLATFORM:-}" = "mac" ]; then
    install_homebrew_if_needed || return 1
    require_homebrew || return 1
    brew install dialog
  else
    if [[ $EUID -ne 0 ]] && ! sudo -v; then
      echo "無法取得 sudo 權限，無法安裝 dialog。" >&2
      return 1
    fi
    sudo apt-get update -qq && sudo apt-get install -y dialog -qq
  fi
}

menu_select() {
  local title="$1"
  shift
  local item
  local tag
  local description
  local dialog_args=()
  local selection
  local status

  MENU_SELECTIONS=""
  for item in "$@"; do
    IFS='|' read -r tag description <<<"$item"
    dialog_args+=("$tag" "$description" "off")
  done

  if [ "${#dialog_args[@]}" -eq 0 ]; then
    return 0
  fi

  selection=$(dialog --clear --separate-output --checklist "$title" 0 0 0 "${dialog_args[@]}" 2>&1 >/dev/tty)
  status=$?
  clear >/dev/tty 2>/dev/null || true

  if [ "$status" -ne 0 ]; then
    echo "已略過：$title"
    return 0
  fi

  MENU_SELECTIONS="$selection"
}

for_each_menu_selection() {
  local selection="$1"
  local selected
  for selected in $selection; do
    "$2" "$selected"
  done
}

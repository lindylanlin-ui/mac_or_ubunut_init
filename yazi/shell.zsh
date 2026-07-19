# Return the shell to the last directory visited in Yazi.
function yazi() {
  local tmp cwd exit_code
  tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return 1

  command yazi --cwd-file="$tmp" "$@"
  exit_code=$?
  if [[ -s "$tmp" ]]; then
    IFS= read -r cwd < "$tmp" || true
    [[ -n "$cwd" && "$cwd" != "$PWD" ]] && builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
  return "$exit_code"
}

function y() {
  yazi "$@"
}

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

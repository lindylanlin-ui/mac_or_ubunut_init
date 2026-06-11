# =====================================================================
# 1. Oh My Zsh 基礎路徑與外掛宣告
# (必須在 source oh-my-zsh.sh 之前！)
# =====================================================================
# Oh My Zsh 的安裝路徑
export ZSH="$HOME/.oh-my-zsh"

# Zsh 主題設定 (clean 是一個簡潔的好選擇)
ZSH_THEME="clean"

# 宣告你要啟用的所有外掛 (已根據您的 install-linux.sh 調整)
# 'git' 是基本, 'aws' 提供aws-cli補全, 'fzf-tab' 'zsh-autosuggestions' 'zsh-syntax-highlighting' 提升效率, 'autojump' 快速跳轉目錄
plugins=(git aws fzf-tab zsh-autosuggestions zsh-syntax-highlighting autojump)

# 載入 Oh My Zsh 核心 (這行會去讀取上面的 plugins 和 theme)
source $ZSH/oh-my-zsh.sh

# =====================================================================
# 2. 外部工具初始化與環境變數
# =====================================================================
# 啟用 autojump (適用於 apt 安裝的路徑)
if [ -f /usr/share/autojump/autojump.sh ]; then
  . /usr/share/autojump/autojump.sh
fi

# 啟用 fzf 的 zsh 整合
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# 如果您有安裝 Go，設定 Go 的工作路徑
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# =====================================================================
# 3. Cloud / K8s / Terraform 相關設定與自動補全
# =====================================================================
# 啟用 bash completion 相容模式 (terraform/aws 等工具需要)
autoload -U +X bashcompinit && bashcompinit

# 設定 kubectl 自動補全
if command -v kubectl &> /dev/null; then
  source <(kubectl completion zsh)
fi

# 設定 terraform 自動補全 (自動尋找 terraform 路徑)
if command -v terraform &> /dev/null; then
  complete -o nospace -C "$(which terraform)" terraform
fi

# 設定 aws-cli 自動補全 (自動尋找 aws_completer 路徑)
if command -v aws_completer &> /dev/null; then
  complete -C "$(which aws_completer)" aws
fi

# =====================================================================
# 4. 個人專屬快捷指令 (Aliases)
# =====================================================================
alias k='kubectl'
alias ktx='kubectx'
alias kns='kubens'
alias tf='terraform'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# =====================================================================
# 5. 提示字元 (Prompt) 設定
# =====================================================================
# 一個簡潔且包含 git 資訊的提示字元
# 格式: user@hostname:~/current/path (git-branch) $
PROMPT='%{$fg[yellow]%}%n%{$reset_color%}@%{$fg[blue]%}%m%{$reset_color%}:%{$fg[cyan]%}%~%{$reset_color%} $(git_prompt_info)%(!.#.$) '

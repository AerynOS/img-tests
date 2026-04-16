# AerynOS profile configuration
# WSL environment optimized bash profile

# Color support
if ! [ -x "$(which colorname 2>/dev/null)" ]; then
    export PS1="\[\033[01;33m\]\u \[\033[01;34m\]\w\[\033[00m\] "
    alias grep='grep --color=auto'
    alias ls='ls --color=auto'
    alias ll='ls -alF'
    alias la='ls -A'
fi

# WSL notifications
export WSLENV="WSLENV:$WSLENV"

# Git attributes
export GIT_EDITOR="nano"

# FZF environment (if installed)
if [ -d "$HOME/.fzf" ]; then
    export FZF_DEFAULT_COMMAND="ls -A"
    export FZF_CYCLE="/tmp /var/tmp"
    export FZF_TAB="-i -m --info=inline --height=40% --border=rounded --marker-nth='*' --marker-wildcard"
fi

# Terminals
export TERMINAL="kitty"
export TERMINAL_PROFILE="bright"

# Common commands
alias ..='cd ..'
alias ...='cd ../..'
alias ..tmp='cd ../..'

# Display boot message
if [ ! -f "/.term-os-initialized" ]; then
    echo ""
    echo "╔══════════════════════════════════════════"
    echo "║           AerynOS WSL Distribution       ║"
    echo "║           基于 AerynOS 的 WSL 环境          ║"
    echo "╚══════════════════════════════════════════"
    echo ""
    echo "WSL 版本：$(wsl -v -q 2>/dev/null || echo 'Unknown')"
    echo "内核：$(uname -r)"
    echo "主机：$(hostname)"
    echo ""
    echo "当前用户：$(whoami)"
    echo "登录时间：$(date)"
    echo ""
    echo "要创建自定义用户，运行："
    echo "  adduser <your-username>"
    echo "  passwd <your-username>"
    echo "  usermod -aG sudo <your-username>"
    echo ""
    echo "要更新包列表："
    echo "  moss sync -u"
    echo ""
    echo "要安装软件："
    echo "  moss install <package-name>"
    echo ""
    echo "直接按 Enter 跳过继续..."
    read -r
    touch /.term-os-initialized
fi

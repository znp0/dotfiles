# Better ls
alias ls='eza --icons'

# Detailed listing
alias ll='eza -lh --icons --git'

# Detailed listing including hidden files
alias la='eza -lah --icons --git'

# Tree view
alias tree='eza --tree --icons'

# Reuse ls completions for eza (avoids defining a separate completion function)
compdef eza=ls

# Better cat
alias cat='bat'

# Core utilities
alias grep='rg --color=auto'
alias rg='rg --color=auto'
alias diff='diff --color=auto'
alias df='df -h'
alias cls="precmd() { precmd() { echo } } && clear"

# Navigation
# -- prevents - being parsed as a flag; cd - jumps to previous directory
alias -- -='cd -'

lf() { # zsh follow lf navigation
    tmp=$(mktemp)
    command lf -last-dir-path="$tmp" "$@"
    if [ -f "$tmp" ]; then
        dir=$(cat "$tmp")
        rm -f "$tmp"
        [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
    fi
}

# Editor
alias zed='zeditor'
alias vi='nvim'

# Misc
alias load-fonts='fc-cache -fv'
alias usage='codexbar usage'

alias evnup='sudo ipsec restart && sleep 1 && sudo ipsec up evnfc-dc && sudo resolvconf -u'
alias evndn='sudo ipsec down evnfc-dc'


alias plytest='sudo plymouthd --debug --debug-file=/tmp/plymouth-debug.log --tty=/dev/tty2; sudo plymouth --show-splash; sleep 3; sudo plymouth --quit'
alias plylog="sudo grep \"Text '\" /tmp/plymouth-debug.log | tail -20"

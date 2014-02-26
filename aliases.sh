
# some more ls aliases
alias ll='ls -l -h'
alias la='ls -A'
alias l='ls -CF'
alias rm='rm -i'
alias cd..='cd ..'
alias svnst='svn st --ignore-externals'
alias k='komodo'
alias s='sublime_text'
alias grin='grin --follow'

alias sshtyaco='nameTerminal YACOSERVER; ssh 192.168.13.96'
alias sshdemo='nameTerminal DEMO;   ssh 192.168.13.140'
alias sshdemotf='nameTerminal DEMOTF;   ssh 192.168.13.142'

# Enables forwarding of the authentication agent connection.
alias sshpro='eval `ssh-agent`;ssh-add'
alias ssh='ssh -A'

alias dotfiles='dotfiles -C ~/.dotfiles/dotfilesrc'
alias grinp='grin -I "*.py"'
alias grinh='grin -I "*.html"'


# Mercurial
alias hs='hg status'
alias hsum='hg summary'
alias hcm='hg commit -m'

alias check='hg st | grep .py | cut -f 2 -d " " | xargs flake8  --ignore="E501,E122,E128"'

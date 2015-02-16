# Stopwatch
alias timer='echo "Timer started. Stop with Ctrl-D." && date && time cat && date'
alias myip="dig +short myip.opendns.com @resolver1.opendns.com"

# some more ls aliases
alias ll='ls -l -h'
alias la='ls -A'
alias l='ls -CF'
alias rm='rm -i'
alias cd..='cd ..'
alias svnst='svn st --ignore-externals'
alias k='komodo'
alias s='sublime_text'

# Enables forwarding of the authentication agent connection.
alias sshpro='eval `ssh-agent`;ssh-add'
alias ssh='ssh -A'

alias dotfiles='dotfiles -C ~/.dotfiles/dotfilesrc'

alias grinp='grin -I "*.py"'
alias grinh='grin -I "*.html"'
alias grinmodels='grin -I "models.py"'
alias grinurls='grin -I "urls.py"'
alias grina='grin -I "admin.py"'
alias grinpo='grin -I "*.po"'

# Mercurial
alias hs='hg status'
alias hsum='hg summary'
alias hcm='hg commit -m'

alias check='hg st | grep .py | cut -f 2 -d " " | xargs flake8  --ignore="E501,E122,E128"'

# docker
alias dl='docker ps -l -q'

# https://hub.github.com/
alias git='hub'

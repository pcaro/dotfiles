# Stopwatch
alias timer='echo "Timer started. Stop with Ctrl-D." && date && time cat && date'
alias myip="dig +short myip.opendns.com @resolver1.opendns.com"

# some more ls aliases
alias ll='ls -l -h'
alias la='ls -A'
alias l='ls -CF'
alias rm='rm -i'
alias cd..='cd ..'
alias s='code'
alias busca='fd'

# Enables forwarding of the authentication agent connection.
alias sshpro='eval `ssh-agent`;ssh-add'
alias ssh='ssh -A'

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


# docker
alias dk='docker'
alias dklc='docker ps -l'  # List last Docker container
alias dklcid='docker ps -l -q'  # List last Docker container ID
alias dklcip='docker inspect -f "{{.NetworkSettings.IPAddress}}" $(docker ps -l -q)'  # Get IP of last Docker container
alias dkps='docker ps'  # List running Docker containers
alias dkpsa='docker ps -a'  # List all Docker containers
alias dki='docker images'  # List Docker images
alias dkrmac='docker rm $(docker ps -a -q)'  # Delete all Docker containers

# This command is a neat shell pipeline to stop all running containers no matter
# where you are and without knowing any container names
alias dkstac="docker ps -q | awk '{print $1}' | xargs -o docker stop"

# kubernetes
alias k='kubectl'
alias kb='kubectl'
alias kga='kubectl get all --show-labels'
alias kls='kubectl get pods --show-labels'
alias klsa='kubectl get pod --all-namespaces'
alias kdp='kubectl describe pod'
# function checks if the application is installed,
# then replaces it with the one given.
# Credit: https://github.com/slomkowski
__add_command_replace_alias() {
    if [ -x "$(command -v $2 2>&1)" ]; then
        alias "$1"="$2"
    fi
}

__add_command_replace_alias git 'hub'
__add_command_replace_alias man 'tldr'
__add_command_replace_alias df 'pydf'

# Stopwatch
alias timer='echo "Timer started. Stop with Ctrl-D." && date && time cat && date'
alias myip="dig +short myip.opendns.com @resolver1.opendns.com"


# cd aliases
alias cd.='cd ..'
alias cd-='cd -'
alias cd..='cd ..'

# some more ls aliases
alias ll='ls -l -h'
alias la='ls -A'
alias l='ls -CF'
alias rm='rm -i'
alias cd..='cd ..'
alias s='code'
alias sgo='code -g'
alias busca='fd'
alias fd='fdfind'
alias bat='batcat'

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
alias dc='docker-compose'
alias dctail='docker-compose logs -f'
alias dklc='docker ps -l'  # List last Docker container
alias dklcid='docker ps -l -q'  # List last Docker container ID
alias dklcip='docker inspect -f "{{.NetworkSettings.IPAddress}}" $(docker ps -l -q)'  # Get IP of last Docker container
alias dkps='docker ps'  # List running Docker containers
alias dkls='docker ps'  # List running Docker containers
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
alias kgrep='kubectl get pods --show-labels | grep '
alias kexec='kubectl exec -it'
alias kns='kubens'


# System shortcuts
alias reboot='sudo shutdown -r now'
alias shutdown='sudo shutdown -h now'
alias paux='ps aux | grep'

# Networking
alias ports='netstat -tulanp'
alias ports-listen='sudo lsof -nP -iTCP -sTCP:LISTEN'



alias glogin='echo "gcloud container clusters get-credentials carto --zone europe-west1-b --project geographica-gs"; gcloud container clusters get-credentials carto --zone europe-west1-b --project geographica-gs'

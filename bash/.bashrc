#!/bin/bash
# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History configuration
HISTCONTROL=ignoreboth:erasedups
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend

# Window size check
shopt -s checkwinsize

# Enable ** globbing
shopt -s globstar

# Less make file friendly for non-text input files
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Color support
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# Function to add directories to PATH (avoid duplicates)
add_to_path() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        export PATH="$1:$PATH"
    fi
}

# Build PATH
add_to_path "$HOME/bin"
add_to_path "$HOME/.local/bin"
add_to_path "$HOME/.cargo/bin"
add_to_path "$HOME/.diff-so-fancy"
add_to_path "/usr/sbin"
add_to_path "/sbin"

# Terminal title function
function nameTerminal() {
    [ "${TERM:0:5}" = "xterm" ] && local ansiNrTab=0
    [ "$TERM" = "rxvt" ] && local ansiNrTab=61
    [ "$TERM" = "konsole" ] && local ansiNrTab=30 ansiNrWindow=0
    [ $ansiNrTab ] && echo -n $'\e'"]$ansiNrTab;$1"$'\a'
    [ $ansiNrWindow -a "$2" ] && echo -n $'\e'"]$ansiNrWindow;$2"$'\a'
}

# Clipboard helper
function to_clip() {
    local message="${1:-"Por favor, proporciona el mensaje adicional"}"
    { cat; echo "$message"; } | xclip -sel clip
}

# Source files if they exist
source_if_exists() {
    [ -f "$1" ] && source "$1"
}

# Load aliases
source_if_exists "$HOME/.aliases"
source_if_exists "$HOME/.aliases_local"

# Load completions
source_if_exists "/etc/bash_completion"
source_if_exists "$HOME/.bash_completion"

# Load functions
source_if_exists "$HOME/.up_function.sh"

# Editor
export EDITOR="${EDITOR:-nano}"

# Python configuration
export PIP_RESPECT_VIRTUALENV=true
export PYTHONSTARTUP="$HOME/.pythonrc.py"

# Development tools
# Ruby - rbenv
if [ -d "$HOME/.rbenv" ]; then
    add_to_path "$HOME/.rbenv/bin"
    eval "$(rbenv init -)"
fi

# Node - fnm (Fast Node Manager)
if [ -d "$HOME/.fnm" ]; then
    add_to_path "$HOME/.fnm"
    eval "$(fnm env --use-on-cd --version-file-strategy=recursive --resolve-engines)"
fi

# Python - uv
command -v uv &>/dev/null && eval "$(uv generate-shell-completion bash)"

# Rust
source_if_exists "$HOME/.cargo/env"

# Git prompt
if [ -f "$HOME/.bash-git-prompt/gitprompt.sh" ]; then
    GIT_PROMPT_THEME=Default_NoExitState_Ubuntu
    source "$HOME/.bash-git-prompt/gitprompt.sh"
fi

# Git flow completion
source_if_exists "$HOME/.dotenv/git-flow-completion.bash"

# Directory tools
command -v direnv &>/dev/null && eval "$(direnv hook bash)"
command -v zoxide &>/dev/null && eval "$(zoxide init bash)"

command -v fzf &>/dev/null && eval "$(fzf --bash)"

# CSS utilities
source_if_exists "$HOME/.css.sh"

# pnpm
if [ -d "$HOME/.local/share/pnpm" ]; then
    export PNPM_HOME="$HOME/.local/share/pnpm"
    case ":$PATH:" in
        *":$PNPM_HOME:"*) ;;
        *) export PATH="$PNPM_HOME:$PATH" ;;
    esac
fi

# Environment variables
export XAUTHORITY="$HOME/.Xauthority"
export GRIN_ARGS="--follow --skip-dirs CVS,RCS,.svn,.hg,.bzr,build,dist,migrations,node_modules,.git"
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

# Chrome/Firefox cache in RAM (optional, uncomment if needed)
# export XDG_CACHE_HOME="/tmp/$USER/dotcache"
# if [ -n "$XDG_CACHE_HOME" ] && [ ! -d "$XDG_CACHE_HOME" ]; then
#     mkdir -p -m 0700 "$XDG_CACHE_HOME"
# fi

# Claude Code working directory
export CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=1
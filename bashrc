
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples


# Set terminal title
# @param string $1  Tab/window title
# @param string $2  (optional) Separate window title
 # The latest version of this software can be obtained here:
# See: http://fvue.nl/wiki/NameTerminal
function nameTerminal() {
    [ "${TERM:0:5}" = "xterm" ]   && local ansiNrTab=0
    [ "$TERM"       = "rxvt" ]    && local ansiNrTab=61
    [ "$TERM"       = "konsole" ] && local ansiNrTab=30 ansiNrWindow=0
        # Change tab title
    [ $ansiNrTab ] && echo -n $'\e'"]$ansiNrTab;$1"$'\a'
        # If terminal support separate window title, change window title as well
    [ $ansiNrWindow -a "$2" ] && echo -n $'\e'"]$ansiNrWindow;$2"$'\a'
    if `qdbus | grep yakuake > /dev/null 2>/dev/null`; then
        local terminalID=$(qdbus org.kde.yakuake  /yakuake/sessions activeTerminalId );
        qdbus org.kde.yakuake /yakuake/tabs setTabTitle $((terminalID)) $1
    fi
} # nameTerminal()

# Usage example
# files-to-prompt utils.ts | to_clip "Algo extra"
# Paste on LLM
function to_clip() {
    local message="${1:-"Por favor, proporciona el mensaje adicional"}"
    { cat; echo "$message"; } | xclip -sel clip
}



# If running interactively, then:
if [ "$PS1" ]; then

    # don't put duplicate lines in the history. See bash(1) for more options
    # export HISTCONTROL=ignoredups

    # check the window size after each command and, if necessary,
    # update the values of LINES and COLUMNS.
    #shopt -s checkwinsize

    # enable color support of ls and also add handy aliases
    if [ "$TERM" != "dumb" ]; then
        eval `dircolors -b`
        alias ls='ls --color=auto'
    fi

    # Aliases
    if [ -f $HOME/.aliases.sh ] ; then
        source $HOME/.aliases.sh
    fi

    # Aliases local
    if [ -f $HOME/.aliases_local.sh ] ; then
        source $HOME/.aliases_local.sh
    fi

    # set a fancy prompt
    # PS1='\u@\h:\w\$ '
    #PS1='\[\033[01;34m\](\[\033[01;31m\]\w\[\033[01;34m\])\n\[\e[0;31m\]\u\[\e[0;37m\]@\[\e[0;33m\]\h\[\e[0;0m\]\$ '
    # set PATH so it includes user's private bin if it exists
    PATH=/usr/sbin:"${PATH}"
    if [ -d ~/bin ] ; then
        PATH=~/bin:"${PATH}":/sbin
    fi


    EDITOR=nano
    export EDITOR

    # enable programmable completion features (you don't need to enable
    # this, if it's already enabled in /etc/bash.bashrc).
    if [ -f /etc/bash_completion ]; then
      . /etc/bash_completion
    fi

    if [ -f $HOME/.bash_completion ]; then
      . $HOME/bash_completion
    fi


    complete -o default -F _pip_completion pip
    # pip bash completion end

    # Virtualenvwrapper modified v function
    # source $HOME/.v_function

    # export WORKON_HOME=$HOME/.virtualenvs
    # source /usr/bin/virtualenvwrapper.sh

    # up function
    source $HOME/.up_function.sh

    # pip virtualenv support
    # http://pypi.python.org/pypi/pip

    # To tell pip to only run if there is a virtualenv currently activated, and to bail if not
    # export PIP_REQUIRE_VIRTUALENV=true
    # To tell pip to automatically use the currently active virtualenv
    export PIP_RESPECT_VIRTUALENV=true
    export PIP_VIRTUALENV_BASE=$WORKON_HOME

    # export PYTHONSTARTUP=~/.pythonrc.py

    # To use Distribute with virtualenv
    export VIRTUALENV_USE_DISTRIBUTE=true

    # pythonbrew
    # [[ -s $HOME/.pythonbrew/etc/bashrc ]] && source $HOME/.pythonbrew/etc/bashrc

    # rvm es como un virtualenv para ruby
    # http://rvm.beginrescueend.com/
    # [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

    # rbenv es menos instrusivo que rvm (RUBY)
    if [ -d $HOME/.rbenv ] ; then
        export PATH="$HOME/.rbenv/bin:$PATH"
        eval "$(rbenv init -)"
    fi

    if [ -d $HOME/.local/bin ] ; then
        export PATH=~/.local/bin:$PATH
    fi

    if [ -d $HOME/.diff-so-fancy ] ; then
        export PATH=~/.diff-so-fancy:$PATH
    fi

    # mercurial prompt by hg-prompt
    # if [ -f $HOME/.prompt.sh ] ; then
    #     source $HOME/.prompt.sh
    # fi
    # https://github.com/magicmonty/bash-git-prompt/
    GIT_PROMPT_THEME=Default_NoExitState_Ubuntu
    source ~/.bash-git-prompt/gitprompt.sh

    if [ -d $HOME/.dotenv/git-flow-completion.bash ] ; then
        source $HOME/.dotenv/git-flow-completion.bash
    fi
    eval "$(direnv hook bash)"

    # fnm
    export PATH=/home/pcaro/.fnm:$PATH
    eval "`fnm env --version-file-strategy=recursive --resolve-engines`"
    
    eval "$(uv generate-shell-completion bash)"

fi # running interactively

# unset JAVA_HOME
# export JAVA_HOME=/usr/lib/jvm/java-6-sun
# unset JDK_HOME
# export JDK_HOME=/usr/lib/jvm/java-6-sun

# export JAVA_ROOT=/usr/lib64/jdk_Oracle
# export JAVA_HOME=/usr/lib64/jdk_Oracle
# export JDK_HOME=/usr/lib64/jdk_Oracle
# export JAVA_BINDIR=/usr/lib64/jdk_Oracle/bin
# export JRE_HOME=/usr/lib64/jdk_Oracle/jre
export XAUTHORITY=$HOME/.Xauthority
export GRIN_ARGS="--follow --skip-dirs CVS,RCS,.svn,.hg,.bzr,build,dist,migrations"

#Keep chrome/firefox cache in ram
# export XDG_CACHE_HOME=/tmp/pcaro/dotcache
if [ ! -f $XDG_CACHE_HOME ];
then
    mkdir -p -m 0700 $XDG_CACHE_HOME
fi

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# I am using rye instead of pyenv
# export PYENV_ROOT="$HOME/.pyenv"
# if [ -z "$PYENV_INITIALIZED" ]; then
#     export PATH="$PYENV_ROOT/bin:$PATH"
#     eval "$(pyenv init -)"
# fi# fnm
export PATH=/home/pcaro/.fnm:$PATH
eval "`fnm env --use-on-cd --version-file-strategy=recursive --resolve-engines`"

# export GOOGLE_APPLICATION_CREDENTIALS=$HOME/.sa_xy_italy.json
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


# rye is a project and package management solution for Python
# But now I am using uv
#if [ -d $HOME/.rye/shims ] ; then
#    source "$HOME/.rye/env"
#fi

# CSS utilities
if [ -f $HOME/.css.sh ] ; then
    source "$HOME/.css.sh"
fi

. "$HOME/.cargo/env"

# pnpm
export PNPM_HOME="/home/pcaro/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=1


# dbt aliases
alias dbtf=/home/pcaro/.local/bin/dbt

# Added by dbt installer
export PATH="$PATH:/home/pcaro/bin"

# dbt aliases
alias dbtf=/home/pcaro/bin/dbt

if [ -x $HOME/.local/bin/zoxide ] ; then
   eval "$(zoxide init bash)"
fi

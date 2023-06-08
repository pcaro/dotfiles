
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

    # pip bash completion start
    _pip_completion()
    {
        COMPREPLY=( $( COMP_WORDS="${COMP_WORDS[*]}" \
                   COMP_CWORD=$COMP_CWORD \
                   PIP_AUTO_COMPLETE=1 $1 ) )
    }
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

    # rbenv es menos instrusivo que rvm
    if [ -d $HOME/.rbenv ] ; then
        export PATH="$HOME/.rbenv/bin:$PATH"
        eval "$(rbenv init -)"
    fi

    # pipsi an other like poetry
    if [ -d $HOME/.local/bin ] ; then
        export PATH=~/.local/bin:$PATH
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

fi # running interactively

# unset JAVA_HOME
# export JAVA_HOME=/usr/lib/jvm/java-6-sun
# unset JDK_HOME
# export JDK_HOME=/usr/lib/jvm/java-6-sun

export JAVA_ROOT=/usr/lib64/jdk_Oracle
export JAVA_HOME=/usr/lib64/jdk_Oracle
export JDK_HOME=/usr/lib64/jdk_Oracle
export JAVA_BINDIR=/usr/lib64/jdk_Oracle/bin
export JRE_HOME=/usr/lib64/jdk_Oracle/jre
export XAUTHORITY=$HOME/.Xauthority
export GRIN_ARGS="--follow --skip-dirs CVS,RCS,.svn,.hg,.bzr,build,dist,migrations"

#Keep chrome/firefox cache in ram
# export XDG_CACHE_HOME=/tmp/pcaro/dotcache
if [ ! -f $XDG_CACHE_HOME ];
then
    mkdir -p -m 0700 $XDG_CACHE_HOME
fi

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

export PYENV_ROOT="$HOME/.pyenv"
if [ -z "$PYENV_INITIALIZED" ]; then
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

export GOOGLE_APPLICATION_CREDENTIALS=$HOME/.sa_xy_italy.json
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# fnm
# export PATH=/home/pcaro/.fnm:$PATH
# eval "`fnm env --use-on-cd`"



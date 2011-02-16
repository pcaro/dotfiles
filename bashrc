
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

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
	alias dir='ls --color=auto --format=vertical'
	#alias vdir='ls --color=auto --format=long'
    fi

    # some more ls aliases
    alias ll='ls -l -h'
    alias la='ls -A'
    alias l='ls -CF'
    alias rm='rm -i'
    alias cd..='cd ..'
    alias svnst='svn st --ignore-externals'
    alias k='komodo'
    alias e='UliPad.py'

    # set a fancy prompt
    # PS1='\u@\h:\w\$ '
    #PS1='\[\e[0;31m\]\u\[\e[0;37m\]@\[\e[0;33m\]\h\[\e[0;36m\](\w)\[\e[0;0m\]\$ '
    # De Enrique
    #PS1='\[\033[01;34m\](\[\033[01;31m\]\w\[\033[01;34m\])\n${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]\$ '
    # Mio modificado de Enrique
    PS1='\[\033[01;34m\](\[\033[01;31m\]\w\[\033[01;34m\])\n\[\e[0;31m\]\u\[\e[0;37m\]@\[\e[0;33m\]\h\[\e[0;0m\]\$ '
    # set PATH so it includes user's private bin if it exists
    if [ -d ~/bin ] ; then
        PATH=~/bin:"${PATH}"
    fi
    
    if [ -d ~/src/devUtils_out/bin ] ; then
        PATH=~/src/devUtils_out/bin:"${PATH}"
    fi
    
    # /var/lib/gems/1.8/bin para compass
    if [ -d /var/lib/gems/1.8/bin ] ; then
        PATH=/var/lib/gems/1.8/bin:"${PATH}"
    fi


    # Me gusta usar el jed
    EDITOR=jed
    export EDITOR


    # If this is an xterm set the title to user@host:dir
    #case $TERM in
    #xterm*)
    #    PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'
    #    ;;
    #*)
    #    ;;
    #esac

    # enable programmable completion features (you don't need to enable
    # this, if it's already enabled in /etc/bash.bashrc).
    if [ -f /etc/bash_completion ]; then
      . /etc/bash_completion
    fi

    if [ -f /etc/django_bash_completion ]; then
       . /etc/django_bash_completion
    fi
fi

FIRST_XLOGIN="$HOME/.first_xlogin"
if [ -f $FIRST_XLOGIN ]; then
        /usr/local/bin/first_xlogin.sh
        rm $FIRST_XLOGIN
fi


# This line was appended by KDE
# Make sure our customised gtkrc file is loaded.
# (This is no longer needed from version 0.8 of the theme engine)
# export GTK2_RC_FILES=$HOME/.gtkrc-2.0

unset JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-6-sun
unset JDK_HOME
export JDK_HOME=/usr/lib/jvm/java-6-sun


# Virtualenvwrapper modified v function
source $HOME/.virtualenvwrapper_bashrc-1.4

# up function
source $HOME/.up_function.sh

# pip virtualenv support
# http://pypi.python.org/pypi/pip

# To tell pip to only run if there is a virtualenv currently activated, and to bail if not
# export PIP_REQUIRE_VIRTUALENV=true
# To tell pip to automatically use the currently active virtualenv
export PIP_RESPECT_VIRTUALENV=true

# To use Distribute with virtualenv
export VIRTUALENV_USE_DISTRIBUTE=true


# Bash shell driver for 'go' (http://code.google.com/p/go-tool/).
function go {
    export GO_SHELL_SCRIPT=$HOME/.__tmp_go.sh
    python -m ~/bin/go $*
    if [ -f $GO_SHELL_SCRIPT ] ; then
        source $GO_SHELL_SCRIPT
    fi
    unset GO_SHELL_SCRIPT
}

# rvm es como un virtualenv para ruby
# http://rvm.beginrescueend.com/
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" 
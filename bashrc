
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
    fi

    # some more ls aliases
    alias ll='ls -l -h'
    alias la='ls -A'
    alias l='ls -CF'
    alias rm='rm -i'
    alias cd..='cd ..'
    alias svnst='svn st --ignore-externals'
    alias k='komodo'
    alias grin='grin --follow'

    # set a fancy prompt
    # PS1='\u@\h:\w\$ '
    PS1='\[\033[01;34m\](\[\033[01;31m\]\w\[\033[01;34m\])\n\[\e[0;31m\]\u\[\e[0;37m\]@\[\e[0;33m\]\h\[\e[0;0m\]\$ '
    # set PATH so it includes user's private bin if it exists
    if [ -d ~/bin ] ; then
        PATH=~/bin:"${PATH}"
    fi

    if [ -d ~/src/devUtils_out/bin ] ; then
        PATH=~/src/devUtils_out/bin:"${PATH}"
    fi

    EDITOR=jed
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
    source $HOME/.v_function

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

    # set PATH so it includes user's private bin if it exists
    if [ -d /home/chroots/libs/bin ] ; then
	PATH=/home/chroots/libs/bin:"${PATH}"
    fi

    # rvm es como un virtualenv para ruby
    # http://rvm.beginrescueend.com/
    # [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

    # rbenv es menos instrusivo que rvm
    if [ -d $HOME/.rbenv ] ; then
	export PATH="$HOME/.rbenv/bin:$PATH"
	eval "$(rbenv init -)"
    fi


    # mercurial prompt by hg-prompt
    if [ -f $HOME/.prompt.sh ] ; then
	    source $HOME/.prompt.sh
    fi


fi

unset JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-6-sun
unset JDK_HOME
export JDK_HOME=/usr/lib/jvm/java-6-sun
unset M2_HOME
export M2_HOME=/home/pcaro/programas/apache-maven-3.0.3

# set PATH so it includes user's private bin if it exists
if [ -d $M2_HOME/bin ] ; then
    PATH=$M2_HOME/bin:"${PATH}"
fi
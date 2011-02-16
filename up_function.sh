
# up function
# See http://daniele.livejournal.com/76011.html

#If you pass no arguments, it just goes up one directory.
#If you pass a numeric argument it will go up that number of directories.
#If you pass a string argument, it will look for a parent directory with that name and go up to it.

function up()
{
    dir=""
    if [ -z "$1" ]; then
        dir=..
    elif [[ $1 =~ ^[0-9]+$ ]]; then
        x=0
        while [ $x -lt ${1:-1} ]; do
            dir=${dir}../
            x=$(($x+1))
        done
    else
        dir=${PWD%/$1/*}/$1
    fi
    cd "$dir";
}

function upstr()
{
    echo "$(up "$1" && pwd)";
}

# List the available environments.
function show_up_options () {
    (pwd | tr / " ") 
}

#
# Set up tab completion.  (Adapted from Arthur Koziel's version at 
# http://arthurkoziel.com/2008/10/11/virtualenvwrapper-bash-completion/)
# 
_ups ()
{
    local cur="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=( $(compgen -W "`show_up_options`" -- ${cur}) )
}

complete -o default -o nospace -F _ups up
complete -o default -o nospace -F _ups upstr

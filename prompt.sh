function hg_prompt() {
  hg prompt "[{tip}]\
{status|modified|unknown}\
{update}\
{ rama:{branch|quiet}}\
{ bookmark:{bookmark}}\
{ tags:{tags|,}}\
{ patches: {patches|join( → )}}
" 2> /dev/null
}

function hg_prompt_color() {
  hg prompt "\[\033[01;34m\][{rev}/{tip}\[\033[01;34m\]]\
{\[\033[01;31m\]{status|modified|unknown}}\
{update}\
{ \[\033[01;34m\]rama:{branch|quiet}}\
{ \[\e[0;33m\]bookmark:{bookmark}}\
{ \[\e[0;33m\]tags:{tags|,}}\
{ \[\033[01;34m\]patches:{patches|join(→)\
|pre_applied(\[\033[01;31m\])|post_applied(\[\e[0;0m\])\
|pre_unapplied(\[\033[30;37m\])|post_unapplied(\[\e[0;0m\])}}" 2> /dev/null
}

function prompt_char {
    git branch >/dev/null 2>/dev/null && echo '±' && return
    hg root >/dev/null 2>/dev/null && echo '☿' && return
    echo '$'
}

function prompt_pwd {
    echo '\[\033[01;31m\]\w\e[0;0m'
}

function vcs_prompt {
    git branch >/dev/null 2>/dev/null && echo $(git_prompt) && return
    hg root >/dev/null 2>/dev/null && echo $(hg_prompt_color) && return
    echo ''
}

function git_prompt {
    echo "$(parse_git_dirty) rama:$(git_current_branch)"
}

function git_current_branch {
    x=$(git branch 2> /dev/null | grep ^* | awk '{print $2}')
    if [ ! -z $x ]
    then
        echo "$x"
    fi
}

function parse_git_dirty {
    status=`git status 2> /dev/null`
    dirty=`    echo -n "${status}" 2> /dev/null | grep -q "Changed but not updated" 2> /dev/null; echo "$?"`
    untracked=`echo -n "${status}" 2> /dev/null | grep -q "Untracked files" 2> /dev/null; echo "$?"`
    ahead=`    echo -n "${status}" 2> /dev/null | grep -q "Your branch is ahead of" 2> /dev/null; echo "$?"`
    newfile=`  echo -n "${status}" 2> /dev/null | grep -q "new file:" 2> /dev/null; echo "$?"`
    renamed=`  echo -n "${status}" 2> /dev/null | grep -q "renamed:" 2> /dev/null; echo "$?"`
    bits=''
    if [ "${dirty}" == "0" ]; then
            bits="${bits}☭"
    fi
    if [ "${untracked}" == "0" ]; then
            bits="${bits}?"
    fi
    if [ "${newfile}" == "0" ]; then
            bits="${bits}*"
    fi
    if [ "${ahead}" == "0" ]; then
            bits="${bits}+"
    fi
    if [ "${renamed}" == "0" ]; then
            bits="${bits}>"
    fi
    echo "${bits}"
}

PS1='\[\033[01;31m\]\w\e[0;0m $(vcs_prompt)\n\[\e[0;31m\]\u\[\e[0;37m\]@\[\e[0;33m\]\h\[\e[0;0m\]$(prompt_char) '

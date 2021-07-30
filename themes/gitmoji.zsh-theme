# This theme is based on jonathan and avit with a few modifications

functions rbenv_prompt_info >& /dev/null || rbenv_prompt_info(){}

function theme_precmd {
    local TERMWIDTH
    (( TERMWIDTH = ${COLUMNS} - 4 ))


    ###
    # Truncate the path if it's too long.

    PR_FILLBAR=""
    PR_PWDLEN=""

    local promptsize=${#${(%):---(%n@%m:%l)---()--}}
    local rubyprompt=`rvm_prompt_info || rbenv_prompt_info`
    local rubypromptsize=${#${rubyprompt}}
    local pwdsize=${#${(%):-%~}}

    if [[ "$promptsize + $rubypromptsize + $pwdsize" -gt $TERMWIDTH ]]; then
      ((PR_PWDLEN=$TERMWIDTH - $promptsize))
    else
      PR_FILLBAR="\${(l.(($TERMWIDTH - ($promptsize + $rubypromptsize + $pwdsize)))..${PR_SPACE}.)}"
    fi

}


setopt extended_glob
theme_preexec () {
    if [[ "$TERM" == "screen" ]]; then
	local CMD=${1[(wr)^(*=*|sudo|-*)]}
	echo -n "\ek$CMD\e\\"
    fi
}

# Determine the time since last commit. If branch is clean,
# use a neutral color, otherwise colors will vary according to time.
function _git_time_since_commit() {
  local last_commit now seconds_since_last_commit
  local minutes hours days years commit_age
  # Only proceed if there is actually a commit.
  if last_commit=$(git log --pretty=format:'%at' -1 2> /dev/null); then
    now=$(date +%s)
    seconds_since_last_commit=$((now-last_commit))

    # Totals
    minutes=$((seconds_since_last_commit / 60))
    hours=$((minutes / 60))
    days=$((hours / 24))
    years=$((days / 365))

    if [[ $years -gt 0 ]]; then
      commit_age="${years}y $((days % 365 ))d "
    elif [[ $days -gt 0 ]]; then
      commit_age="${days}d $((hours % 24))h "
    elif [[ $hours -gt 0 ]]; then
      commit_age+="${hours}h $(( minutes % 60 ))m "
    else
      commit_age="${minutes}m"
    fi

    echo "⏰ ${ZSH_THEME_GIT_TIME_SINCE_COMMIT_NEUTRAL}${commit_age}%{$reset_color%}"
  fi
}

git_commit_id() {
  if comm_id=$(git rev-parse --short HEAD 2>/dev/null); then
    echo "📌 ${comm_id}"
  fi
}

setprompt () {
    ###
    # Need this so the prompt will work.

    setopt prompt_subst


    ###
    # See if we can use colors.

    autoload zsh/terminfo
    for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE GREY; do
	eval PR_$color='%{$terminfo[bold]$fg[${(L)color}]%}'
	eval PR_LIGHT_$color='%{$fg[${(L)color}]%}'
	(( count = $count + 1 ))
    done
    PR_NO_COLOUR="%{$terminfo[sgr0]%}"

    ###
    # Modify Git prompt
    # ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[yellow]%}"
    ZSH_THEME_GIT_PROMPT_PREFIX="%{$FG[220]%}\uE0A0 "
    ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
    ZSH_THEME_GIT_PROMPT_DIRTY=" ${FG[133]}"
    ZSH_THEME_GIT_PROMPT_CLEAN=" ${FG[118]}🕊"

    ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%}➕"
    ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[blue]%}➰"
    ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}❌"
    ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[magenta]%}💡"
    ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[yellow]%}🔔"
    ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[yellow]%}🌟"

    ###
    # See if we can use extended characters to look nicer.
    # UTF-8 Fixed

    if [[ $(locale charmap) == "UTF-8" ]]; then
	PR_SET_CHARSET=""
	PR_SHIFT_IN=""
	PR_SHIFT_OUT=""
	PR_HBAR="─"
	PR_SPACE=" "
        PR_ULCORNER="┌"
        PR_LLCORNER="└"
        PR_LRCORNER="┘"
        PR_URCORNER="┐"
    else
        typeset -A altchar
        set -A altchar ${(s..)terminfo[acsc]}
        # Some stuff to help us draw nice lines
        PR_SET_CHARSET="%{$terminfo[enacs]%}"
        PR_SHIFT_IN="%{$terminfo[smacs]%}"
        PR_SHIFT_OUT="%{$terminfo[rmacs]%}"
        PR_HBAR='$PR_SHIFT_IN${altchar[q]:--}$PR_SHIFT_OUT'
        PR_ULCORNER='$PR_SHIFT_IN${altchar[l]:--}$PR_SHIFT_OUT'
        PR_LLCORNER='$PR_SHIFT_IN${altchar[m]:--}$PR_SHIFT_OUT'
        PR_LRCORNER='$PR_SHIFT_IN${altchar[j]:--}$PR_SHIFT_OUT'
        PR_URCORNER='$PR_SHIFT_IN${altchar[k]:--}$PR_SHIFT_OUT'
     fi


    ###
    # Decide if we need to set titlebar text.

    case $TERM in
	xterm*)
	    PR_TITLEBAR=$'%{\e]0;%(!.-=*[ROOT]*=- | .)%n@%m:%~ | ${COLUMNS}x${LINES} | %y\a%}'
	    ;;
	screen)
	    PR_TITLEBAR=$'%{\e_screen \005 (\005t) | %(!.-=[ROOT]=- | .)%n@%m:%~ | ${COLUMNS}x${LINES} | %y\e\\%}'
	    ;;
	*)
	    PR_TITLEBAR=''
	    ;;
    esac


    ###
    # Decide whether to set a screen title
    if [[ "$TERM" == "screen" ]]; then
	PR_STITLE=$'%{\ekzsh\e\\%}'
    else
	PR_STITLE=''
    fi


    ###
    # Finally, the prompt.  on %{$fg[magenta]%}\uE0A0      $(_git_time_since_commit)

    PROMPT='$PR_SET_CHARSET$PR_STITLE${(e)PR_TITLEBAR}\
$PR_CYAN$PR_ULCORNER$PR_HBAR\
$PR_GREEN%$PR_PWDLEN<...<%~%<< \
$PR_LIGHT_BLUE%{$reset_color%}`git_prompt_info``git_prompt_status` ${(e)PR_FILLBAR} %F{81}$(_git_time_since_commit) %{$fg[white]%}$(git_commit_id)$PR_BLUE\

$PR_CYAN$PR_LLCORNER$PR_HBAR\
➜$PR_NO_COLOUR '

    # display exitcode on the right when >0
    return_code="%(?..%{$fg[red]%}%? ↵ %{$reset_color%})"
    RPROMPT=' $return_code\
$PR_NO_COLOUR'

    PS2='$PR_CYAN$PR_HBAR\
$PR_BLUE$PR_HBAR(\
$PR_LIGHT_GREEN%_$PR_BLUE)$PR_HBAR\
$PR_CYAN$PR_HBAR$PR_NO_COLOUR '
}

setprompt

autoload -U add-zsh-hook
add-zsh-hook precmd  theme_precmd
add-zsh-hook preexec theme_preexec

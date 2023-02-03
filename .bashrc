# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples
# If not running interactively, don't do anything

cd ~

alias python=python3
alias pip=pip3

alias clip='xclip -sel clip'
alias gbr="git branch | egrep -v "master" | xargs git branch -D"
alias ee="explorer.exe ."
alias k=kubectl

export K8S_NAMESPACE=kimi450

# get logs for pod where only 1 pod is expected
logs() {
  kubectl logs -f $(kubectl get pods | egrep "$1" | awk '{print $1}')
}

# delete resource based on the pattern provided
# default resource is pod
delete() {
  if [[ -z "$2" && -z "$1" ]]; then
    echo "usage: delete <POD_PATTERN>"
    echo "usage: delete <KUBERNETES_RESOURCE> <RESOURCE_PATTERN>"
    echo "Provide pattern to delete pod, or resource and pattern"
    return
  fi
  resource="pod"
  pattern="$1"
  if [ -n "$2" ]; then
    resource="$1"
    pattern="$2"
  fi
  kubectl delete ${resource} $(kubectl get ${resource} | egrep "${pattern}" | awk '{print $1}')
}

# kubectl exec into pod matching the pattern with given command, default command is bash
execit() {
  command="bash"
  pattern="$1"
  if [ -n "$2" ]; then
    pattern="$1"
    command="$2"
  fi
  kubectl exec -it $(kubectl get pod | egrep "${pattern}" | awk '{print $1}') -- ${command}
}

# remove docker images with string in name
rmi () {
  docker rmi $(docker images | egrep "$1")
}

# patch service to nodeport
# usage: patch <service>
# usage: patch <service> <nodeport to use>
patch () {
  if [ -z "$2" ]; then
    # plain patch to nodeport
    kubectl patch service $1 --type='json' -p "[{'op':'replace','path':'/spec/type','value':'NodePort'}]"
  else
    # patch to nodeport with specific port
    kubectl patch service $1 --type='json' -p "[{'op':'replace','path':'/spec/type','value':'NodePort'},{'op':'replace','path':'/spec/ports/0/nodePort','value':$2}]"
  fi
}

# switch namespace
kn() {
    kubens $1
    if [ $? -ne 0 ]; then
        if [ $# -eq 0 ]; then
            echo -e "Missing namespace...\nusage: kn NAMESPACE"
            return 1
        fi
        kubectl config set-context --current --namespace=$1
    fi
}

# get current namespace
kcn() {
  kubectl config view --minify --output 'jsonpath={..namespace}'; echo
}

# switch context
alias kk=kubectx

# current context
kcc() {
  kubectl config view --minify --output 'jsonpath={..current-context}'; echo
}

# get every single resource available on the cluster
# or provide a list of resources you are interested in
# eg: "kall pods service"
kall() {
    lst=$@
    if [ -z $1 ]; then
        lst=`kubectl api-resources --no-headers | awk '{print $1}'`
    fi
    for resource in $lst; do
        echo -e "***${resource}***";
        kubectl get $resource;
    done
}


# monitor given namespace (or K8S_NAMESPACE) services and pods
monitor() {
  NAMESPACE=$1
  if [ -z "$1" ]; then
     NAMESPACE=$(kcn)
  fi
  watch "kubectl get pods,svc -n $NAMESPACE"
}

# uninstall everything and reset namespace
# usage: reset
#        Defaults to resetting $K8S_NAMESPACE
# usage: reset <namespace>
function reset {
  if [ -z "$1" ]; then
    NAMESPACE=$K8S_NAMESPACE
  else
    NAMESPACE=$1
  fi
  kn $NAMESPACE > /dev/null && echo "On $(kcc):$(kcn)"
  helm delete $(helm ls --all --short --namespace $NAMESPACE) --namespace $NAMESPACE
  kubectl delete namespace $NAMESPACE && kubectl create namespace $NAMESPACE || kubectl create namespace $NAMESPACE
}


# login to docker to make life easier
# better command prompt
PROMPT_COMMAND=__prompt_command # Func to gen PS1 after CMDs

parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

__prompt_command() {
 local EXIT="$?" # This needs to be first

 local RCol='\[\e[0m\]'

 local Red='\[\e[0;31m\]'
 local Gre='\[\e[0;32m\]'
 local BYel='\[\e[1;33m\]'
 local BBlu='\[\e[1;34m\]'
 local Pur='\[\e[0;35m\]'

 dashes="--"
   if [ ${#EXIT} -eq 3 ]; then
   dashes=""
  elif [ ${#EXIT} -eq 2 ]; then
   dashes="-"
  fi
  PS1="${Gre}[$(cat /sys/class/power_supply/BAT0/capacity)%] $(kcc):$(kcn) ${BYel}\t ${RCol}"
 # PS1="${Gre}$(kcc):$(kcn) ${BYel}\t ${RCol}"
 if [ $EXIT != 0 ]; then
 PS1+="[${Red}${dashes}${EXIT}${RCol}]" # Add red if exit code non 0
 else
  PS1+="[${Gre}${dashes}${EXIT}${RCol}]"
 fi
 PS1+="${Pur} \w ${BYel}$(parse_git_branch) $ ${RCol}"
}

# Colors for git stuff
export GIT_PS1_SHOWCOLORHINTS="true"
export GIT_PS1_SHOWUPSTREAM="auto"
export GIT_PS1_SHOWDIRTYSTATE="true"
#PROMPT_COMMAND='__git_ps1 "\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]" " > "'

case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

export HISTSIZE=1000
autoload -U compinit
autoload colors
compinit
colors

# disable scroll lock feature (Ctrl-s)
stty -ixon -ixoff

#Path
export PATH=$HOME/.bin:$PATH

# Env Vars
export EDITOR=vim
export CLICOLOR=1

# Options
setopt EXTENDED_HISTORY # add timestamps to history
setopt LOCAL_OPTIONS # allow functions to have local options
setopt LOCAL_TRAPS # allow functions to have local traps
setopt PROMPT_SUBST
setopt COMPLETE_IN_WORD
setopt IGNORE_EOF
setopt AUTO_CD
setopt HIST_IGNORE_DUPS
setopt APPEND_HISTORY # adds history
setopt INC_APPEND_HISTORY SHARE_HISTORY  # adds history incrementally and share it across sessions
setopt HIST_IGNORE_ALL_DUPS  # don't record dupes in history
setopt HIST_REDUCE_BLANKS

# Completion
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' # case insensitive completion
zstyle ':completion:*:default' menu 'select=0' # menu-style

vc_prompt_info() {
  echo "%{$fg[cyan]%}[$(vcprompt -f %b%m%u)]%{$reset_color%}"
}

cwd() {
  echo "%{$fg[magenta]%}%~%{$reset_color%}"
}

function refresh_ssh() {
  if [[ -n $TMUX ]]; then
    NEW_SSH_AUTH_SOCK=`tmux showenv | grep SSH_AUTH_SOCK | cut -d = -f 2`
    if [[ -n $NEW_SSH_AUTH_SOCK ]] && [[ -S $NEW_SSH_AUTH_SOCK ]]; then
      echo 'refreshing SSH_AUTH_SOCK'
      SSH_AUTH_SOCK=$NEW_SSH_AUTH_SOCK
    fi
  fi
}

export PROMPT="
\$(cwd) \$(vc_prompt_info)
%{$fg[blue]%}%%%{$reset_color%} "

bindkey -e
bindkey '^r' history-incremental-search-backward

if [ -e "$HOME/.aliases" ]; then
  source "$HOME/.aliases"
fi

source "$HOME/.ruby_heap"
source "$HOME/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

ZSH_DISABLE_COMPFIX=true
# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="duke"

# aliases
alias dotfiles="cd ~/projects/dotfiles"
alias zshconfig="vim ~/.zshrc"
alias ohmyzsh="vim ~/.oh-my-zsh"
alias pipeline='rubocop; brakeman; rails_best_practices; rspec'
alias g='git'
alias up='docker-compose up'
alias upb='docker-compose up --build'
alias dex='docker-compose exec $(basename "$PWD")'
alias drun='docker-compose run $(basename "$PWD")'
alias position="git fetch --prune && git checkout devel && git rebase origin/devel && (git branch --merged | egrep -v \"(^\*|master|devel)\" | xargs git branch -d)"
alias readmyenv="export \$(grep -v '^#' .env | xargs)"

# autocomplete
zstyle ':completion:*' menu select

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# PLUGINS
plugins=(git lol asdf archlinux)

source $ZSH/oh-my-zsh.sh
unsetopt correct_all

# Customize to your needs...
export PATH=$PATH:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/usr/bin/core_perl
export PATH=$PATH:~/.xmonad/bin
export PATH=$HOME/bin:$PATH
export EDITOR=vim

[[ -s $HOME/.tmuxinator/scripts/tmuxinator ]] && source $HOME/.tmuxinator/scripts/tmuxinator
export PAGER=most
export MANPAGER=most
export TERM=xterm-256color
export GITHUB_TOKEN=

# fixing suspend/resume on vim
alias vim="stty stop '' -ixoff ; vim"
ttyctl -f

bindkey -v
bindkey '^r' history-incremental-search-backward

unset GREP_OPTIONS

notes() {
  if [ ! -z "$1" ]; then
    # Using the "$@" here will take all parameters passed into
    # this function so we can place everything into our file.
    echo "$@" >> "$HOME/notes.md"
  else
    # If no arguments were passed we will take stdout and place
    # it into our notes instead.
    cat - >> "$HOME/notes.md"
  fi
}

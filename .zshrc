# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="duke"

# Example aliases
alias dotfiles="cd ~/projects/dotfiles"
alias zshconfig="vim ~/.zshrc"
alias ohmyzsh="vim ~/.oh-my-zsh"

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
plugins=(git lol archlinux)

source $ZSH/oh-my-zsh.sh
unsetopt correct_all

# Customize to your needs...
export PATH=$GEM_HOME/.rvm/bin
export PATH=$PATH:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/usr/bin/core_perl
export PATH=$PATH:/opt/android-sdk/tools:/opt/android-sdk/platform-tools
export PATH=$PATH:~/.cabal/bin:~/.xmonad/bin
export PATH=$HOME/bin:$PATH
export EDITOR=vim

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
[[ -s $HOME/.tmuxinator/scripts/tmuxinator ]] && source $HOME/.tmuxinator/scripts/tmuxinator
export PAGER=most
export MANPAGER=most
export TERM=xterm-256color

# fixing suspend/resume on vim
alias vim="stty stop '' -ixoff ; vim"
export GITHUB_TOKEN="141ac5143d7fc424a203f514e10dc40d"
ttyctl -f

bindkey -v
bindkey '^r' history-incremental-search-backward

PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting

unset GREP_OPTIONS

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Disable compfix
ZSH_DISABLE_COMPFIX=true

# Path to your oh-my-zsh configuration
ZSH=$HOME/.oh-my-zsh
ZSH_THEME="powerlevel10k/powerlevel10k"

# Aliases
alias dotfiles="cd ~/dotfiles"
alias zshconfig="vim ~/.zshrc"
alias ohmyzsh="vim ~/.oh-my-zsh"
alias pipeline='rubocop; brakeman; rails_best_practices; rspec'
alias g='git'
alias up='docker-compose up'
alias upb='docker-compose up --build'
alias dex='docker-compose exec $(basename "$PWD")'
alias drun='docker-compose run $(basename "$PWD")'
alias readmyenv="set -o allexport && source .env && set +o allexport"

# Autocomplete
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes

autoload -U add-zsh-hook

# Uncomment following line if you want to disable autosetting terminal title
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Plugins
plugins=(
  1password
  bundler
  docker
  docker-compose
  git
  gitfast
  jsontools
  rails
  ruby
  sudo
  asdf
  archlinux
  zsh-autosuggestions
  zsh-syntax-highlighting
  #zsh-autocomplete
)

source $ZSH/oh-my-zsh.sh
unsetopt correct_all

# Environment Variables
export PATH=$PATH:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin
export EDITOR=nvim
export PAGER=most
export MANPAGER=most
export TERM=xterm-256color

# Avoid storing sensitive information directly in the .zshrc file
# export GITHUB_TOKEN=your_token_here

ttyctl -f

# Key Bindings
bindkey -v
bindkey '^r' history-incremental-search-backward

# Notes Function
notes() {
  if [ ! -z "$1" ]; then
    echo "$@" >> "$HOME/notes.md"
  else
    cat - >> "$HOME/notes.md"
  fi
}

# Powerlevel10k Configuration
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Hubstaff Configuration
export PATH="$HOME/.sre-toolkit/bin:$PATH"
export HUBSTAFF_HOME=$HOME/projects/hubstaff/
alias hub-start='hs-local services start && hs-local account start && hs-local server start'

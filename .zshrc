# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

ZSH_DISABLE_COMPFIX=true
# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh
ZSH_THEME="powerlevel10k/powerlevel10k"

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
alias readmyenv="set -o allexport && source .env && set +o allexport"

# autocomplete
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes

autoload -U add-zsh-hook

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# PLUGINS
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

# Customize to your needs...
export PATH=$PATH:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin
export EDITOR=nvim

export PAGER=most
export MANPAGER=most
export TERM=xterm-256color
export GITHUB_TOKEN=

# fixing suspend/resume on vim
alias vim="stty stop '' -ixoff ; vim"
ttyctl -f

bindkey -v
bindkey '^r' history-incremental-search-backward

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

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

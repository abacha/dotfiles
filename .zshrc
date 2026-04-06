# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Disable compfix to avoid warnings about insecure directories
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
alias docker-compose='docker compose'

# Prefer Windows Chrome when running GUI actions from WSL
if [[ -x /mnt/c/Windows/System32/cmd.exe ]]; then
  export BROWSER="/mnt/c/Windows/System32/cmd.exe /C start chrome"
  alias browser='cmd.exe /C start chrome'
else
  export BROWSER=wslview
fi

# Docker autocomplete
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes

autoload -U add-zsh-hook

COMPLETION_WAITING_DOTS="true"

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
  # asdf
  archlinux
  zsh-autosuggestions
  zsh-syntax-highlighting
  # zsh-autocomplete
  fzf
)

source $ZSH/oh-my-zsh.sh
unsetopt correct_all

ttyctl -f

# asdf Configuration
export PATH="$HOME/.asdf/bin:$HOME/.asdf/shims:$PATH"
if [ -d "${ASDF_DATA_DIR:-$HOME/.asdf}" ]; then
  fpath=(${ASDF_DATA_DIR:-$HOME/.asdf}/completions $fpath)
  source "${ASDF_DATA_DIR:-$HOME/.asdf}/asdf.sh"
fi

# initialise completions with ZSH's compinit
autoload -Uz compinit && compinit

# Key Bindings
bindkey -v
# bindkey '^r' history-incremental-search-backward

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

# fzf keybindings
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh

# OpenClaw Completion
[[ -f /home/abacha/.openclaw/completions/openclaw.zsh ]] && source /home/abacha/.openclaw/completions/openclaw.zsh

# >>> Hubstaff SRE Toolkit >>>
export PATH="/home/abacha/.sre-toolkit/bin:$PATH"
# <<< Hubstaff SRE Toolkit <<<

# Codex Auth Rotation
alias codex-hs="cp ~/.codex/auth-hs.json ~/.codex/auth.json && echo 'Codex switched to Hubstaff (hs)'"
alias codex-personal="cp ~/.codex/auth-personal.json ~/.codex/auth.json && echo 'Codex switched to Personal'"
export EDITOR="vim"

# Claude Auth Rotation
alias claude-hs="cp ~/.claude/.credentials-hs.json ~/.claude/.credentials.json && echo 'Claude switched to Hubstaff (hs)'"
alias claude-personal="cp ~/.claude/.credentials-personal.json ~/.claude/.credentials.json && echo 'Claude switched to Personal'"


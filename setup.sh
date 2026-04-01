#!/bin/bash

set -e

NODE_VERSION=25.7.0
RUBY_VERSION=3.3.8
PYTHON_VERSION=3.12.2

# Function to install basic packages
install_basic_packages() {
  echo "📦 Installing basic packages..."
  sudo apt install -y tmux vim zsh git most make build-essential
}

# Function to install extra packages (gh, jq, ffmpeg)
install_extra_packages() {
  echo "🛠️ Installing extra packages (gh, jq, ffmpeg)..."
  # Add GitHub CLI official repository
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  
  sudo apt update
  sudo apt install -y gh jq ffmpeg
}

# Function to setup Docker
setup_docker() {
  echo "🐳 Setting up Docker..."
  curl -sSL https://get.docker.com/ | sh
  sudo apt install -y docker-compose
  sudo gpasswd -a $USER docker
  newgrp docker || true
}

# Function to configure npm global installs for the current user
setup_npm_user_prefix() {
  mkdir -p "$HOME/.local"
  npm config set prefix "$HOME/.local"
  export PATH="$HOME/.local/bin:$PATH"
}

# Function to setup Node.js via ASDF
setup_node() {
  echo "🟢 Setting up Node.js via ASDF..."
  [ -d "$HOME/.asdf" ] || setup_asdf
  source ~/.asdf/asdf.sh 2>/dev/null || true
  asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git || true
  asdf install nodejs "$NODE_VERSION"
  asdf global nodejs "$NODE_VERSION"
  setup_npm_user_prefix

  echo "🧶 Enabling Corepack..."
  corepack enable || true
}

# Function to setup Neovim
setup_neovim() {
  echo "📝 Setting up Neovim..."
  sudo add-apt-repository ppa:neovim-ppa/unstable -y
  sudo apt install neovim -y

  echo "🔌 Installing packer.nvim..."
  git clone --depth 1 https://github.com/wbthomason/packer.nvim $@ ~/.local/share/nvim/site/pack/packer/start/packer.nvim || true

  sudo apt install ripgrep -y
}

# Function to setup ASDF
setup_asdf() {
  echo "🧰 Setting up ASDF..."
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1 || true
}

# Function to setup Ruby
setup_ruby() {
  echo "💎 Setting up Ruby via ASDF..."
  sudo apt install -y openssl gcc zlib1g-dev libffi-dev libyaml-dev libssl-dev
  
  source ~/.asdf/asdf.sh 2>/dev/null || true
  asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git || true
  asdf install ruby $RUBY_VERSION
  asdf global ruby $RUBY_VERSION
}

# Function to setup Python
setup_python() {
  echo "🐍 Setting up Python via ASDF..."
  sudo apt install -y make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
    
  source ~/.asdf/asdf.sh 2>/dev/null || true
  asdf plugin add python || true
  asdf install python $PYTHON_VERSION
  asdf global python $PYTHON_VERSION
}

# Function to setup uv
setup_uv() {
  echo "⚡ Installing uv (Astral's Python Manager)..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
}

# Function to setup AI CLIs
setup_ai_clis() {
  echo "🤖 Installing AI CLIs..."
  source ~/.asdf/asdf.sh 2>/dev/null || true
  command -v npm >/dev/null 2>&1 || setup_node
  setup_npm_user_prefix
  npm install -g @openai/codex @google/gemini-cli @anthropic-ai/claude-code
}

# Function to setup Zsh
setup_zsh() {
  echo "🐚 Setting up Zsh..."
  sudo chsh -s /bin/zsh $USER
  
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "✨ Installing Oh-My-Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi

  echo "🎨 Installing Powerlevel10k theme..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k || true

  echo "🔌 Installing Zsh plugins..."
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || true
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting || true
  git clone https://github.com/marlonrichert/zsh-autocomplete ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete || true
}

# Function to create symbolic links for dotfiles
create_symlinks() {
  echo "🔗 Creating symbolic links for dotfiles..."
  ln -sf ~/dotfiles/.zshrc ~/
  ln -sf ~/dotfiles/.tmux.conf ~/
  ln -sf ~/dotfiles/.gitconfig ~/
  ln -sf ~/dotfiles/.inputrc ~/
  ln -sf ~/dotfiles/.pryrc ~/
  ln -sf ~/dotfiles/.gemrc ~/
  ln -sf ~/dotfiles/.tool-versions ~/

  mkdir -p ~/.config
  ln -sf ~/dotfiles/nvim ~/.config/
  ln -sf ~/dotfiles/tmuxinator ~/.config/
}

# Function to setup Tmux
setup_tmux() {
  echo "🖥️ Setting up Tmux..."
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm || true
}

# Function to setup Tmuxinator
setup_tmuxinator() {
  echo "🚀 Setting up Tmuxinator..."
  source ~/.asdf/asdf.sh 2>/dev/null || true
  gem install tmuxinator
  ln -sf ~/dotfiles/.tmuxinator ~/.config/
}

# Function to setup AI config links
# Function to setup secrets from 1Password
setup_secrets() {
  echo "🔐 Setting up ~/.env from 1Password..."
  
  if command -v op >/dev/null 2>&1; then
    if op whoami >/dev/null 2>&1 || op account get >/dev/null 2>&1; then
      op read "op://Personal/Dotfiles Env/text" > ~/.env 2>/dev/null && \
      chmod 600 ~/.env && \
      echo "✅ ~/.env created successfully."
    else
      echo "⚠️ 1Password CLI is not authenticated. Skip fetching .env."
    fi
  else
    echo "⚠️ 1Password CLI (op) not found. Skipping secrets setup."
  fi
}

setup_ai_config() {
  echo "🤖 Setting up AI config links..."

  mkdir -p ~/dotfiles/ai/conventions

  # Shared agent definitions
  mkdir -p ~/.codex ~/.claude ~/.gemini ~/.codex/rules
  ln -sfn ~/dotfiles/ai ~/.codex/agents
  ln -sfn ~/dotfiles/ai ~/.claude/agents
  ln -sfn ~/dotfiles/ai ~/.gemini/agents

  # Shared global rules file for each CLI
  ln -sfn ~/dotfiles/ai/conventions/global-rules.md ~/.claude/CLAUDE.md
  ln -sfn ~/dotfiles/ai/conventions/global-rules.md ~/.gemini/GEMINI.md
  ln -sfn ~/dotfiles/ai/conventions/global-rules.md ~/.codex/rules/default.rules

  echo "📂 Setting up project AGENTS.md and CLAUDE.md symlinks..."
  GITIGNORE_FILE=$(git config --global core.excludesfile || echo "$HOME/.gitignore")
  touch "$GITIGNORE_FILE"
  git config --global core.excludesfile "$GITIGNORE_FILE"
  if ! grep -q "^AGENTS.md$" "$GITIGNORE_FILE"; then
    echo "AGENTS.md" >> "$GITIGNORE_FILE"
  fi
  if ! grep -q "^CLAUDE.md$" "$GITIGNORE_FILE"; then
    echo "CLAUDE.md" >> "$GITIGNORE_FILE"
  fi

  for const_file in ~/dotfiles/ai/constitutions/*.md; do
    if [ -f "$const_file" ]; then
      proj_name=$(basename "$const_file" .md)
      
      target_dir=$(find ~/ -maxdepth 4 -type d -name "$proj_name" 2>/dev/null | while read d; do
        if [ -d "$d/.git" ]; then
          echo "$d"
          break
        fi
      done | head -n 1)

      if [ -n "$target_dir" ] && [ -d "$target_dir" ]; then
        rm -f "$target_dir/AGENTS.md"
        ln -s "$const_file" "$target_dir/AGENTS.md"
        rm -f "$target_dir/CLAUDE.md"
        ln -s "$const_file" "$target_dir/CLAUDE.md"
        echo "   ✅ Symlinked $proj_name -> $target_dir/{AGENTS.md, CLAUDE.md}"
      fi
    fi
  done
}

# Function to setup WSL
# Function to setup WSL
setup_wsl() {
  echo "🪟 Setting up WSL..."
  sudo apt install -y xclip wslu

  echo "🌐 Setting up Windows browser as default in WSL..."
  sudo update-alternatives --set x-www-browser /usr/bin/wslview || true
  sudo update-alternatives --install /usr/bin/gnome-www-browser gnome-www-browser /usr/bin/wslview 30 || true
  sudo update-alternatives --set gnome-www-browser /usr/bin/wslview || true
  xdg-mime default wslview.desktop x-scheme-handler/http || true
  xdg-mime default wslview.desktop x-scheme-handler/https || true
  xdg-mime default wslview.desktop text/html || true
}

# Main function to orchestrate the setup
main() {
  echo "🚀 Starting dotfiles setup..."
  install_basic_packages
  install_extra_packages
  setup_docker
  setup_asdf
  setup_node
  setup_neovim
  setup_ruby
  setup_python
  setup_uv
  setup_ai_clis
  setup_zsh
  create_symlinks
  setup_secrets
  setup_ai_config
  setup_tmux
  setup_tmuxinator

  if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
    echo "🐧 WSL detected. Installing additional packages..."
    setup_wsl
  fi

  echo "🔄 Updating git submodules..."
  git submodule update --init --recursive
  
  echo "🎉 Setup complete! Restart your shell or run 'exec zsh' to apply changes."
}

resolve_function() {
  case "$1" in
    basic|packages) echo "install_basic_packages" ;;
    extra) echo "install_extra_packages" ;;
    docker) echo "setup_docker" ;;
    node) echo "setup_node" ;;
    neovim|nvim) echo "setup_neovim" ;;
    asdf) echo "setup_asdf" ;;
    ruby) echo "setup_ruby" ;;
    python) echo "setup_python" ;;
    uv) echo "setup_uv" ;;
    ai-clis|clis) echo "setup_ai_clis" ;;
    zsh) echo "setup_zsh" ;;
    symlinks|links) echo "create_symlinks" ;;
    secrets) echo "setup_secrets" ;;
    ai) echo "setup_ai_config" ;;
    tmux) echo "setup_tmux" ;;
    tmuxinator|mux) echo "setup_tmuxinator" ;;
    wsl) echo "setup_wsl" ;;
    install_basic_packages|install_extra_packages|setup_docker|setup_node|setup_neovim|setup_asdf|setup_ruby|setup_python|setup_uv|setup_ai_clis|setup_zsh|create_symlinks|setup_secrets|setup_ai_config|setup_tmux|setup_tmuxinator|setup_wsl) echo "$1" ;;
    *) return 1 ;;
  esac
}

usage() {
  echo "Usage: ./setup.sh [function]"
  echo ""
  echo "Run without arguments to execute the full setup."
  echo ""
  echo "Run './setup.sh help' to see supported shorthand names."
}

if [ $# -eq 0 ]; then
  main
elif [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$1" = "help" ]; then
  usage
else
  fn=$(resolve_function "$1" || true)
  [ -n "$fn" ] || { echo "Error: unknown function '$1'"; usage; exit 1; }
  "$fn"
fi
exit 0

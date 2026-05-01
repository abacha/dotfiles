#!/bin/bash

set -e

NODE_VERSION=25.7.0
RUBY_VERSION=3.3.8
PYTHON_VERSION=3.12.2

apt_update_quiet() {
  sudo apt-get update -qq >/dev/null
}

apt_install_quiet() {
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$@" >/dev/null
}

add_apt_repository_quiet() {
  sudo add-apt-repository -y "$1" >/dev/null 2>&1
}

# Function to install basic packages
install_basic_packages() {
  echo "📦 Installing basic packages..."
  apt_install_quiet tmux vim zsh git most make build-essential bubblewrap fzf
}

# Function to install extra packages (gh, jq, ffmpeg)
install_extra_packages() {
  echo "🛠️ Installing extra packages (gh, jq, ffmpeg)..."
  # Add GitHub CLI official repository
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  
  apt_update_quiet
  apt_install_quiet gh jq ffmpeg
}

# Function to setup Docker
setup_docker() {
  echo "🐳 Setting up Docker..."

  if command -v docker >/dev/null 2>&1; then
    echo "Docker is already installed. Skipping Docker install script."
  else
    curl -fsSL https://get.docker.com/ | sh
  fi

  if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
    apt_install_quiet docker-compose || echo "Failed to install docker-compose via apt, skipping."
  fi

  if getent group docker >/dev/null 2>&1 && ! id -nG "$USER" | grep -qw docker; then
    sudo usermod -aG docker "$USER"
    echo "Added $USER to the docker group. Restart your shell or log out/in for this to take effect."
  fi
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
  asdf plugin list 2>/dev/null | grep -qx nodejs || asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
  asdf install nodejs "$NODE_VERSION"
  asdf global nodejs "$NODE_VERSION"
  asdf reshim nodejs "$NODE_VERSION"
  setup_npm_user_prefix

  echo "🧶 Enabling Corepack..."
  if command -v corepack >/dev/null 2>&1 && [ "$(command -v corepack)" != "/usr/bin/corepack" ]; then
    corepack enable --install-directory "$HOME/.local/bin" || true
  else
    echo "Corepack is not bundled with this ASDF Node install. Skipping."
  fi
}

# Function to setup Neovim
setup_neovim() {
  echo "📝 Setting up Neovim..."
  
  if grep -qEi "(debian|proxmox)" /etc/os-release; then
    echo "🐧 Debian/Proxmox detected. Installing Neovim via pre-built binary..."
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    sudo rm -rf /opt/nvim
    sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
    sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
    rm nvim-linux-x86_64.tar.gz
  else
    add_apt_repository_quiet ppa:neovim-ppa/unstable
    apt_install_quiet neovim
  fi

  echo "🔌 Installing packer.nvim..."
  if [ ! -d "$HOME/.local/share/nvim/site/pack/packer/start/packer.nvim/.git" ]; then
    git clone --depth 1 https://github.com/wbthomason/packer.nvim "$HOME/.local/share/nvim/site/pack/packer/start/packer.nvim"
  else
    echo "packer.nvim already installed. Skipping."
  fi

  apt_install_quiet ripgrep
}

# Function to setup ASDF
setup_asdf() {
  echo "🧰 Setting up ASDF..."
  if [ ! -d "$HOME/.asdf/.git" ]; then
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch "v0.14.1"
  else
    git -C "$HOME/.asdf" fetch --tags origin
    git -C "$HOME/.asdf" checkout "v0.14.1"
  fi

  # Make asdf available immediately within this script process.
  export PATH="$HOME/.asdf/bin:$HOME/.asdf/shims:$PATH"
  source "$HOME/.asdf/asdf.sh" 2>/dev/null || true
}

# Function to setup Ruby
setup_ruby() {
  echo "💎 Setting up Ruby via ASDF..."
  apt_install_quiet openssl gcc zlib1g-dev libffi-dev libyaml-dev libssl-dev
  
  source ~/.asdf/asdf.sh 2>/dev/null || true
  asdf plugin list 2>/dev/null | grep -qx ruby || asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
  asdf install ruby $RUBY_VERSION
  asdf global ruby $RUBY_VERSION
}

# Function to setup Python
setup_python() {
  echo "🐍 Setting up Python via ASDF..."
  apt_install_quiet make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
    
  source ~/.asdf/asdf.sh 2>/dev/null || true
  asdf plugin list 2>/dev/null | grep -qx python || asdf plugin add python
  asdf install python $PYTHON_VERSION
  asdf global python $PYTHON_VERSION
}

# Function to setup uv
setup_uv() {
  echo "⚡ Installing uv (Astral's Python Manager)..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
}

# Function to setup zoxide
setup_zoxide() {
  echo "🚀 Installing zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
}

# Function to setup AI CLIs
setup_ai_clis() {
  echo "🤖 Installing AI CLIs..."
  local existing_claude_target

  source ~/.asdf/asdf.sh 2>/dev/null || true
  command -v npm >/dev/null 2>&1 || setup_node
  setup_npm_user_prefix

  npm install -g @openai/codex || true
  npm install -g @google/gemini-cli || true

  if [ -L "$HOME/.local/bin/claude" ]; then
    existing_claude_target="$(readlink "$HOME/.local/bin/claude")"
  else
    existing_claude_target=""
  fi

  if [ -e "$HOME/.local/bin/claude" ] && [[ "$existing_claude_target" != *".local/lib/node_modules/@anthropic-ai/claude-code/"* ]]; then
    echo "Claude CLI binary already exists at ~/.local/bin/claude. Skipping npm install for @anthropic-ai/claude-code."
  else
    npm install -g @anthropic-ai/claude-code || true
  fi
}

# Function to setup Zsh
setup_zsh() {
  local zsh_custom

  echo "🐚 Setting up Zsh..."
  sudo chsh -s /bin/zsh $USER
  
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "✨ Installing Oh-My-Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi

  zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  echo "🎨 Installing Powerlevel10k theme..."
  if [ ! -d "$zsh_custom/themes/powerlevel10k/.git" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$zsh_custom/themes/powerlevel10k"
  else
    echo "Powerlevel10k already installed. Skipping."
  fi

  echo "🔌 Installing Zsh plugins..."
  if [ ! -d "$zsh_custom/plugins/zsh-autosuggestions/.git" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_custom/plugins/zsh-autosuggestions"
  else
    echo "zsh-autosuggestions already installed. Skipping."
  fi
  if [ ! -d "$zsh_custom/plugins/zsh-syntax-highlighting/.git" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$zsh_custom/plugins/zsh-syntax-highlighting"
  else
    echo "zsh-syntax-highlighting already installed. Skipping."
  fi
  if [ ! -d "$zsh_custom/plugins/zsh-autocomplete/.git" ]; then
    git clone https://github.com/marlonrichert/zsh-autocomplete "$zsh_custom/plugins/zsh-autocomplete"
  else
    echo "zsh-autocomplete already installed. Skipping."
  fi
}

# Function to create symbolic links for dotfiles
create_symlinks() {
  echo "🔗 Creating symbolic links for dotfiles..."
  ln -sf ~/dotfiles/.zshrc ~/
  ln -sf ~/dotfiles/.p10k.zsh ~/
  ln -sf ~/dotfiles/.tmux.conf ~/
  ln -sf ~/dotfiles/.gitconfig ~/
  ln -sf ~/dotfiles/.inputrc ~/
  ln -sf ~/dotfiles/.pryrc ~/
  ln -sf ~/dotfiles/.gemrc ~/
  ln -sf ~/dotfiles/.tool-versions ~/
  ln -sf ~/dotfiles/.gitignore_global ~/.gitignore

  mkdir -p ~/.config
  ln -sf ~/dotfiles/nvim ~/.config/
  ln -sf ~/dotfiles/tmuxinator ~/.config/
}

# Function to setup Tmux
setup_tmux() {
  echo "🖥️ Setting up Tmux..."
  if [ ! -d "$HOME/.tmux/plugins/tpm/.git" ]; then
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  else
    echo "TPM already installed. Skipping."
  fi
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
  apt_install_quiet xclip wslu xdg-utils

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
  setup_zoxide
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
    zoxide) echo "setup_zoxide" ;;
    ai-clis|clis) echo "setup_ai_clis" ;;
    zsh) echo "setup_zsh" ;;
    symlinks|links) echo "create_symlinks" ;;
    secrets) echo "setup_secrets" ;;
    ai) echo "setup_ai_config" ;;
    tmux) echo "setup_tmux" ;;
    tmuxinator|mux) echo "setup_tmuxinator" ;;
    wsl) echo "setup_wsl" ;;
    install_basic_packages|install_extra_packages|setup_docker|setup_node|setup_neovim|setup_asdf|setup_ruby|setup_python|setup_uv|setup_zoxide|setup_ai_clis|setup_zsh|create_symlinks|setup_secrets|setup_ai_config|setup_tmux|setup_tmuxinator|setup_wsl) echo "$1" ;;
    *) return 1 ;;
  esac
}

usage() {
  cat <<'EOF'
Usage: ./setup.sh [function|alias]

Run without arguments to execute the full setup.

Supported aliases:
  basic, packages      install_basic_packages
  extra                install_extra_packages
  docker               setup_docker
  node                 setup_node
  neovim, nvim         setup_neovim
  asdf                 setup_asdf
  ruby                 setup_ruby
  python               setup_python
  uv                   setup_uv
  zoxide               setup_zoxide
  ai-clis, clis        setup_ai_clis
  zsh                  setup_zsh
  symlinks, links      create_symlinks
  secrets              setup_secrets
  ai                   setup_ai_config
  tmux                 setup_tmux
  tmuxinator, mux      setup_tmuxinator
  wsl                  setup_wsl

You can also pass the full function name directly.
EOF
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

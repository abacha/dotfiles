#!/bin/bash

# Function to install basic packages
install_basic_packages() {
    echo "Installing basic packages..."
    sudo apt install -y tmux vim zsh git most make build-essential
}

# Function to setup Docker
setup_docker() {
    echo "Setting up Docker..."
    sudo apt install -y docker-compose
    sudo gpasswd -a $USER docker
    newgrp docker
}

# Function to setup Node.js
setup_node() {
    echo "Setting up Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
}

# Function to setup Neovim
setup_neovim() {
    echo "Setting up Neovim..."
    sudo add-apt-repository ppa:neovim-ppa/unstable -y
    sudo apt install neovim -y

    echo "Installing Vim-Plug..."
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    sudo apt install ripgrep -y
}

# Function to setup ASDF
setup_asdf() {
    echo "Setting up ASDF..."
    sudo apt install -y openssl gcc zlib1g-dev libffi-dev libyaml-dev libssl-dev
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1
    asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
}

# Function to setup Zsh
setup_zsh() {
    echo "Setting up Zsh..."
    chsh --s /bin/zsh

    echo "Installing Oh-My-Zsh..."
    #sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    echo "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

    echo "Installing Zsh plugins..."
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/marlonrichert/zsh-autocomplete ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete
}

# Function to create symbolic links for dotfiles
create_symlinks() {
    echo "Creating symbolic links for dotfiles..."
    ln -sf ~/dotfiles/.vimrc ~/
    ln -sf ~/dotfiles/.zshrc ~/
    ln -sf ~/dotfiles/.tmux.conf ~/
    ln -sf ~/dotfiles/.gitconfig ~/
    ln -sf ~/dotfiles/.inputrc ~/
    ln -sf ~/dotfiles/.pryrc ~/
    mkdir -p ~/.config/nvim
    ln -sf ~/dotfiles/init.vim ~/.config/nvim
}

# Function to setup Tmux
setup_tmux() {
    echo "Setting up Tmux..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
}

# Main function to orchestrate the setup
main() {
    install_basic_packages
    setup_docker
    setup_node
    setup_neovim
    setup_asdf
    setup_zsh
    create_symlinks
    setup_tmux
}

# Execute the main function
main

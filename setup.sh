sudo apt install -y tmux vim zsh git ack

# SETUP RVM
#gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
#\curl -sSL https://get.rvm.io | bash -s stable --ruby

# SETUP ASDF

# SETUP OH-MY-ZSH
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

git clone https://github.com/marlonrichert/zsh-autocomplete ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete                                                                                 1 ↵

ln -sf ~/dotfiles/.vimrc ~/
ln -sf ~/dotfiles/.zshrc ~/
ln -sf ~/dotfiles/.tmux.conf ~/
ln -sf ~/dotfiles/.gitconfig ~/
ln -sf ~/dotfiles/.inputrc ~/
ln -sf ~/dotfiles/.pryrc ~/

cp duke.zsh-theme ~/.oh-my-zsh/themes/


git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
chsh --s /bin/zsh


# SETUP TMUX
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

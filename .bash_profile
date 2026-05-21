# Load shared shell environment variables
if [ -f "$HOME/.shell_env" ]; then
  source "$HOME/.shell_env"
fi

# Load standard bashrc
if [ -f "$HOME/.bashrc" ]; then
  source "$HOME/.bashrc"
fi

# Global environment for all shells
export ASDF_DATA_DIR="$HOME/.asdf"
export PATH="$HOME/.asdf/bin:$PATH"
export PATH="${ASDF_DATA_DIR}/shims:$PATH"
export PATH="$HOME/.local/bin:$PATH:/usr/local/sbin:/usr/sbin:/sbin:/snap/bin"
export PATH="$HOME/.sre-toolkit/bin:$PATH"
export PNPM_HOME="$HOME/.local/share/pnpm"
[[ ":$PATH:" != *":$PNPM_HOME:"* ]] && export PATH="$PNPM_HOME:$PATH"
export EDITOR=nvim
export PAGER=most
export MANPAGER=most
export BROWSER=wslview

if [ -f "$HOME/.env" ]; then
  set -a
  source "$HOME/.env"
  set +a
fi

if [ -f '/opt/google-cloud-sdk/path.zsh.inc' ]; then
  . '/opt/google-cloud-sdk/path.zsh.inc'
fi

if [[ $- == *i* ]] && [ -f '/opt/google-cloud-sdk/completion.zsh.inc' ]; then
  . '/opt/google-cloud-sdk/completion.zsh.inc'
fi

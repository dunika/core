# Volta 
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

if [[ -r "$HOME/.cargo/env" ]]; then
  source "$HOME/.cargo/env"
fi

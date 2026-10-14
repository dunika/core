# PATH and Library Configuration
# Paths are managed in order of priority (earlier = higher priority)

# Deno
export PATH="$HOME/.deno/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

# Pipx (Python package manager)
export PATH="$HOME/.local/bin:$PATH"

# Rust
export PATH="$HOME/.cargo/bin:$PATH"

# VS Code CLI
export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"

# Volta (Node version manager)
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# RubyGems executables for Homebrew Ruby
if [[ -x "$BREW_PREFIX/opt/ruby/bin/ruby" ]]; then
  export GEM_HOME="$HOME/.gem/ruby/$("$BREW_PREFIX/opt/ruby/bin/ruby" -e 'print RbConfig::CONFIG["ruby_version"]')"
  export PATH="$("$BREW_PREFIX/opt/ruby/bin/ruby" -e 'print Gem.bindir'):$PATH"
fi

export PATH=$PATH:$HOME/.maestro/bin

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Tool versions
if (( $+commands[mise] )); then
  eval "$(mise activate zsh)"
fi

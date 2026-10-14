# Zsh Configuration
# ===================

CORE_ZSH_DIR="${${(%):-%x}:A:h}"

# Completion directory
export ZSH_COMPDUMP="${ZDOTDIR:-$HOME}/.zcompdump"

# Homebrew
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
if ! (( $+commands[brew] )); then
  print -u2 'Core requires Homebrew. See the README quick setup.'
  return 1
fi
# Cache brew prefix for performance
BREW_PREFIX=$(brew --prefix) || return 1
export BREW_PREFIX

# Enable Powerlevel10k instant prompt. Should stay close to the top of .zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Zsh Options
# -----------
setopt HIST_IGNORE_ALL_DUPS  # Remove older duplicate entries from history
setopt HIST_REDUCE_BLANKS    # Remove superfluous blanks from history items
setopt INC_APPEND_HISTORY    # Save history entries as soon as they are entered
setopt SHARE_HISTORY         # Share history between all sessions
setopt AUTO_CD               # Change directory just by typing its name
setopt INTERACTIVE_COMMENTS  # Allow comments in interactive mode
setopt MAGIC_EQUAL_SUBST     # Enable filename expansion for arguments of the form 'anything=expression'

# History
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

# Completion System
# -----------------
[[ -d "$HOME/.docker/completions" ]] && fpath=("$HOME/.docker/completions" $fpath)
autoload -Uz compinit
compinit -d "$ZSH_COMPDUMP"

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
# Colored completion (different colors for dirs/files/etc)
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
# Command descriptions
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'
# Warnings
zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'

# Plugins from Homebrew
# ---------------------
source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "$BREW_PREFIX/share/zsh-history-substring-search/zsh-history-substring-search.zsh"

# Key bindings for history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# enhancd
# -------
if [[ -o interactive ]]; then
  source "$CORE_ZSH_DIR/enhancd/init.sh"
  # export ENHANCD_FILTER="fzy"
fi

# Powerlevel10k Theme
# --------------------
source "$BREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme"
# p10k configure
source "$CORE_ZSH_DIR/.p10k.zsh"

# Custom Scripts
# --------------
source "$CORE_ZSH_DIR/_core/aliases.sh"
source "$CORE_ZSH_DIR/_core/git.sh"
source "$CORE_ZSH_DIR/_core/paths_and_libs.sh"

# Work Configuration
# ------------------
if [ -f "${ZDOTDIR:-$HOME}/work/work.sh" ]; then
  source "${ZDOTDIR:-$HOME}/work/work.sh"
fi
# Note: Homebrew paths are set via 'brew shellenv' in .zshrc

# ============================================
# VS Code Shell Integration for Copilot
# Fix for terminal completion detection issue
# https://github.com/orgs/community/discussions/161238
# ============================================

if [[ "$TERM_PROGRAM" == "vscode" ]]; then
  # Disable RPROMPT in VS Code (causes detection issues)
  unset RPROMPT
  unset RPS1

  # Disable transient prompt in VS Code (interferes with command detection)
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=off
  typeset -g POWERLEVEL9K_DISABLE_RPROMPT=true

  # Completely disable right prompt in VS Code
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()

  # Load VS Code shell integration
  [[ -f "$(code --locate-shell-integration-path zsh)" ]] && \
  . "$(code --locate-shell-integration-path zsh)"

fi

# Increase open file limit for large monorepos / VS Code
ulimit -n 65536 2>/dev/null

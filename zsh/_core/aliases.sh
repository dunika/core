# Reload zsh configuration
alias reset='source "${ZDOTDIR:-$HOME}/.zshrc"'

# System info
alias specs="neofetch"

# Validation aliases
alias nval="(export JEST_SUPPRESS_LOGS=true && export VITEST_SUPPRESS_LOGS=true && clear && npm run lint && npm test && npm run build)"
alias pval="(export JEST_SUPPRESS_LOGS=true && export VITEST_SUPPRESS_LOGS=true && clear && pnpm lint && pnpm test && pnpm build)"

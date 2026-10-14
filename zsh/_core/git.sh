# Git aliases and commands
# https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/git/git.plugin.zsh

# Source git functions
source "${0:A:h}/git_functions.sh"

# Push/Pull
alias gp="git pull"
alias gpp="git push --force-with-lease --force-if-includes"

# Commit
gc() {
  git_commit "$@" && gpp
}
# Undo last commit
guc() {
  git_assert_not_protected || return 1
  git reset --soft HEAD~1
}

# Branch operations
alias grb="git_rename_branch"
alias gco="git checkout"
alias gcb="git checkout -"  # checkout previous branch

# Stash
alias gs="git stash --include-untracked"
alias gsp="git stash pop"

# Rebase
alias grc="git rebase --continue"
alias gra="git rebase --abort"

# Main branch
alias gcm="git fetch && git checkout \$(git_main_branch) && git pull"
gbm() { gcm && git checkout -b "$@"; }

# Main operations
alias grm="git_squash_and_rebase_onto_main"
alias gsm="git_squash_from_branch_main"

# Delete merged branches
alias gbda=git_delete_merged_branches

# Fetch all with cleanup
alias gfa="git fetch --all --tags --prune"

# Print help for git aliases
git_help() {
  cat << 'EOF'
Git Aliases Help
================

Push/Pull:
----------
  gp                    Git pull
  gpp                   Git push with force-with-lease

Commit:
-------
  gc <message>          Stage all and commit with message, then force push
  guc                   Undo last commit (soft reset to HEAD~1)

Branch Operations:
------------------
  gco                   Git checkout
  grb <new_name>        Rename current branch (local + remote)
  gcb                   Checkout previous branch
  gcm                   Checkout main & pull
  gbm <name>            Create new branch from main
  gbda [-d|-r]          Delete all merged branches (optional dry-run/remote prune)

Stash:
------
  gs                    Git stash
  gsp                   Git stash pop

Rebase:
-------
  grc                   Git rebase --continue
  gra                   Git rebase --abort
  grm [message]         Squash & rebase onto main, then force push
  gsm [message]         Squash commits from main branch

Fetch:
------
  gfa                   Fetch all with prune

Advanced Functions:
-------------------
  git_squash_from_branch <base> [msg]    Squash commits from base branch
  git_rebase_onto_branch <base>          Rebase onto base branch
  git_main_branch                        Get main/master branch name
  git_current_branch                     Get current branch name
  git_protected_branches                 Get protected branches (from GitHub API or defaults)
  git_dev_branch                         Get development branch name
  git_assert_clean_worktree              Check if worktree is clean
  git_assert_not_protected               Guard against destructive ops on protected branches
  git_rename_branch <new_name>           Rename branch (local + remote)
  git_delete_merged_branches             Delete merged branches interactively

EOF
}

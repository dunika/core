git_assert_clean_worktree() {
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "Uncommitted changes. Please commit or stash them first." >&2
    return 1
  fi
  return 0
}

git_current_branch() {
  git symbolic-ref --quiet --short HEAD 2>/dev/null || {
    echo "Error: detached HEAD or no commits yet." >&2
    return 1
  }
}

git_main_branch() {
  for ref in refs/heads/main refs/heads/master refs/remotes/origin/main refs/remotes/origin/master; do
    if git show-ref -q --verify "$ref"; then
      echo "${ref##*/}"
      return 0
    fi
  done
  echo "main"
}

git_protected_branches() {
  local cache_dir repo_root cache_file
  cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/git-protected-branches"
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -n "$repo_root" ]]; then
    cache_file="$cache_dir/$(printf '%s' "$repo_root" | tr '/ ' '__').txt"
  fi

  # Try to get protected branches from GitHub API if gh CLI is available
  if command -v gh &> /dev/null; then
    local protected
    if protected=$(gh api repos/:owner/:repo/branches --jq '.[] | select(.protected == true) | .name' 2>/dev/null) && [[ -n "$protected" ]]; then
      if [[ -n "$cache_file" ]]; then
        mkdir -p "$cache_dir" >/dev/null 2>&1
        # A cached fallback makes this more resilient when the GitHub API is unavailable.
        printf '%s\n' "$protected" > "$cache_file"
      fi
      printf '%s\n' "$protected"
      return 0
    fi
  fi

  if [[ -n "$cache_file" && -r "$cache_file" ]]; then
    # Expire cache after 24 hours (86400 seconds)
    local cache_mtime now
    cache_mtime=$(stat -f %m "$cache_file" 2>/dev/null || echo 0)
    now=$(date +%s)
    if (( now - cache_mtime < 86400 )); then
      cat "$cache_file"
      return 0
    fi
  fi

  echo "Error: Unable to fetch protected branches from GitHub API and no cache available" >&2
  return 1
}

git_assert_not_protected() {
  local branch
  branch=$(git_current_branch) || return 1
  local main
  main=$(git_main_branch)
  if [[ "$branch" == "$main" ]]; then
    echo "Error: refusing destructive operation on $main" >&2
    return 1
  fi
  local protected
  if protected=$(git_protected_branches 2>/dev/null) && [[ -n "$protected" ]]; then
    if grep -Fxq "$branch" <<< "$protected"; then
      echo "Error: refusing destructive operation on protected branch '$branch'" >&2
      return 1
    fi
  fi
  return 0
}

git_rename_branch() {
  if [[ -z "$1" ]]; then
    echo "Usage: $0 <new_branch>" >&2
    return 1
  fi

  git_assert_clean_worktree || return 1

  local new_branch 
  new_branch="$1"

  local old_branch
  old_branch=$(git_current_branch) || return 1

  [[ "$new_branch" == "$old_branch" ]] && {
    echo "Already on '$new_branch'"
    return 0
  }

  git fetch --prune origin

  if git ls-remote --exit-code --heads origin "$new_branch" >/dev/null; then
    echo "Remote branch '$new_branch' already exists." >&2
    return 1
  fi

  git branch -m "$new_branch"

  # Atomic push: create new_branch and delete old_branch on remote in one transaction.
  # The :"$old_branch" refspec (empty src) tells git to delete that remote ref.
  if ! git push --set-upstream --atomic origin "$new_branch" :"$old_branch"; then
    echo "Push failed — rolling back."
    git branch -M "$old_branch"   # best effort rollback
    git push origin :"$new_branch" >/dev/null 2>&1   # remote branch deletion
    return 1
  fi
}

git_dev_branch() {
  git rev-parse --git-dir &>/dev/null || return 1

  for b in development main master; do
    if git show-ref -q --verify "refs/remotes/origin/$b"; then
      echo "$b"
      return 0
    fi
  done

  echo master
  return 0
}

# Usage
# git_squash_from_branch <base_branch> [<message>]
git_squash_from_branch() {
  local base_branch="$1"
  if [[ -z "$base_branch" ]]; then
    echo "Error: You must specify a base branch."
    return 1
  fi

  git_assert_clean_worktree || return 1

  echo "Fetching origin/$base_branch"
  git fetch origin "$base_branch" || return 1

  local base
  base=$(git merge-base HEAD "origin/$base_branch") || return 1

  local commit_count
  commit_count=$(git rev-list --count "$base"..HEAD)
  if (( commit_count == 0 )); then
    echo "Nothing to squash…"
    return 0
  fi

  local message
  message=${2:-$(git log --reverse --no-merges --format=%s "$base"..HEAD | head -n1)}

  echo "Squashing commits"
  git reset --soft "$base"
  if ! git commit -m "$message"; then
    echo "Error: commit failed after reset. Your changes are staged — run 'git commit' to retry." >&2
    return 1
  fi

  echo "Squashed $commit_count commits into one."
}

git_rebase_onto_branch() {
  local base_branch="$1"
  local skip_fetch="${2:-false}"
  if [[ -z "$base_branch" ]]; then
    echo "Error: You must specify a base branch."
    return 1
  fi

  git_assert_clean_worktree || return 1

  if [[ "$skip_fetch" != "true" ]]; then
    git fetch origin "$base_branch"
  fi
  echo "Rebasing onto origin/$base_branch"
  git rebase "origin/$base_branch" || return 1

  if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
    echo "No upstream branch set. Setting it to origin/$(git_current_branch)."
    git push --set-upstream origin "$(git_current_branch)" || return 1
  fi

  echo "Pushing rewritten history"
  if ! git push --force-with-lease --force-if-includes; then
    echo "Error: push failed. Your local branch has been rebased but the remote is unchanged." >&2
    return 1
  fi

  echo "Rebased $(git rev-list --count "origin/$base_branch"..HEAD) commits onto origin/$base_branch."
}

# Usage
# git_squash_and_rebase_onto_main [<message>]
git_squash_and_rebase_onto_main() {
  git_assert_not_protected || return 1
  local main_branch
  main_branch=$(git_main_branch)
  git_squash_from_branch "$main_branch" "$1" || return 1
  git_rebase_onto_branch "$main_branch" "true" || return 1
}

git_squash_from_branch_main() {
  git_squash_from_branch "$(git_main_branch)" "$1" || return 1
}

git_commit() {
  # If nothing is staged, stage everything
  if [[ -z "$(git diff --cached --name-only)" ]]; then
    git add -A
  fi
  git commit -m "$*"
}

git_delete_merged_branches() {
  local protected current_branch dry_run delete_remote main_branch
  dry_run=false
  delete_remote=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run|-d)
        dry_run=true
        ;;
      --remote|-r)
        delete_remote=true
        ;;
      --help|-h)
        echo "Usage: git_delete_merged_branches [--dry-run|-d] [--remote|-r]" >&2
        return 0
        ;;
      *)
        echo "Usage: git_delete_merged_branches [--dry-run|-d] [--remote|-r]" >&2
        return 1
        ;;
    esac
    shift
  done

  protected=$(git_protected_branches) || return 1
  current_branch=$(git_current_branch 2>/dev/null || true)
  main_branch=$(git_main_branch 2>/dev/null || true)

  local branch_cmd branch_line branch remote_exists answer
  if git for-each-ref --merged=HEAD --format='%(refname:short)' refs/heads >/dev/null 2>&1; then
    branch_cmd=(git for-each-ref --merged=HEAD --format='%(refname:short)' refs/heads)
  else
    branch_cmd=(git branch --merged)
  fi

  while IFS= read -r branch_line; do
    branch=$(printf '%s' "$branch_line" | sed -e 's/^[*[:space:]]*//' -e 's/^branch=//' -e 's/[[:space:]]*$//')

    [[ -z "$branch" ]] && continue
    if [[ -n "$current_branch" && "$branch" == "$current_branch" ]]; then
      continue
    fi
    if [[ -n "$main_branch" && "$branch" == "$main_branch" ]]; then
      continue
    fi
    if [[ -n "$protected" ]] && grep -Fxq "$branch" <<< "$protected"; then
      continue
    fi

    remote_exists=false
    if $delete_remote; then
      if command -v gh >/dev/null 2>&1; then
        if gh api repos/:owner/:repo/branches/"$branch" >/dev/null 2>&1; then
          remote_exists=true
        fi
      elif git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
        remote_exists=true
      fi
    fi

    if $dry_run; then
      echo "Would delete merged branch: $branch"
      if $delete_remote && $remote_exists; then
        echo "Would also delete remote origin/$branch"
      fi
      continue
    fi

    if git branch -d "$branch"; then
      if $delete_remote && $remote_exists; then
        read -r -p "Delete remote branch origin/$branch? [y/N] " answer
        case "$answer" in
          [Yy]*)
            if command -v gh >/dev/null 2>&1; then
              if gh api --method DELETE "repos/:owner/:repo/git/refs/heads/$branch" >/dev/null 2>&1; then
                echo "Deleted remote branch origin/$branch via gh"
              else
                echo "gh failed; falling back to git push"
                git push origin ":$branch"
              fi
            else
              git push origin ":$branch"
            fi
            ;;
          *)
            echo "Skipped remote branch origin/$branch"
            ;;
        esac
      fi
    fi
  done < <("${branch_cmd[@]}")
}

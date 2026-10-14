#!/bin/bash
set -euo pipefail

if [[ $# -gt 1 ]]; then
  echo 'Usage: bash setup.sh [path/to/.zshrc]' >&2
  exit 1
fi

core_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
target="${1:-${ZDOTDIR:-$HOME}/.zshrc}"
source_line="$(printf 'source %q' "$core_dir/zsh/.zshrc")"

if [[ -d "$target" || ( -L "$target" && ! -e "$target" ) ]]; then
  echo "Cannot update configuration file: $target" >&2
  exit 1
fi

if [[ -f "$target" ]] && grep -Fqx -- "$source_line" "$target"; then
  echo "Core is already configured in $target"
  exit 0
fi

mkdir -p "$(dirname "$target")"
if [[ -f "$target" ]]; then
  backup="$(mktemp "$target.backup.XXXXXX")"
  cp "$target" "$backup"
  echo "Backup: $backup"
fi

printf '\n# Core\n%s\n' "$source_line" >> "$target"
echo "Core configured in $target. Start a new terminal to load it."

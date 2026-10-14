#!/bin/bash
set -euo pipefail

core_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT

fixture="$test_dir/core with spaces"
test_home="$test_dir/home"
mkdir -p "$fixture/zsh/_core" "$test_home"
cp "$core_dir/zsh/_core/setup.sh" "$fixture/zsh/_core/setup.sh"
printf 'CORE_SETUP_PROBE=loaded\n' > "$fixture/zsh/.zshrc"
setup_script="$fixture/zsh/_core/setup.sh"
target="$test_dir/custom/.zshrc"
mkdir -p "$(dirname "$target")"
printf '# Existing config\nexport KEEP_THIS=yes' > "$target"
cp "$target" "$test_dir/original"

env HOME="$test_home" bash "$setup_script" "$target" > /dev/null
zsh -f -c 'source "$1"; [[ "$KEEP_THIS" == yes && "$CORE_SETUP_PROBE" == loaded ]]' setup-test "$target" || {
  echo 'Setup did not preserve the existing config and load Core from its actual path.' >&2
  exit 1
}
backups=("$target".backup.*)
[[ ${#backups[@]} == 1 ]]
cmp "$test_dir/original" "${backups[0]}"
cp "$target" "$test_dir/installed"

env HOME="$test_home" bash "$setup_script" "$target" > /dev/null
cmp "$test_dir/installed" "$target"
backups=("$target".backup.*)
[[ ${#backups[@]} == 1 ]]

env HOME="$test_home" ZDOTDIR="$test_home" bash "$setup_script" > /dev/null
zsh -f -c 'source "$1"; [[ "$CORE_SETUP_PROBE" == loaded ]]' setup-test "$test_home/.zshrc"
[[ ! -L "$target" && ! -L "$test_home/.zshrc" ]]

if env HOME="$test_home" bash "$setup_script" "$test_home" > /dev/null 2>&1; then
  echo 'Setup accepted a directory as the configuration file.' >&2
  exit 1
fi

env HOME="$test_home" zsh -f -c 'unset NODE_OPTIONS; source "$1"; [[ "$VOLTA_HOME" == "$HOME/.volta" && -z "${NODE_OPTIONS-}" ]]' env-test "$core_dir/zsh/.zshenv"
env HOME="$test_home" zsh -f -c 'BREW_PREFIX="$2"; source "$1"; [[ "$PNPM_HOME" == "$HOME/Library/pnpm" ]]' paths-test "$core_dir/zsh/_core/paths_and_libs.sh" "$test_dir/no-ruby" 2> "$test_dir/paths-errors"
[[ ! -s "$test_dir/paths-errors" ]]

echo 'Setup tests passed: preserves and backs up existing config, supports spaces and custom paths, repeats safely, and creates no symlinks.'

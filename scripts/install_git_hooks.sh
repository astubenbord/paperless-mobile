#!/usr/bin/env bash
# Installs git hooks from the hooks/ directory into .git/hooks/.
# Run once after cloning: bash scripts/install_git_hooks.sh
set -Euo pipefail

__script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
readonly __script_dir

REPO_ROOT="$__script_dir/.."
HOOKS_SOURCE="$REPO_ROOT/hooks"
HOOKS_TARGET="$REPO_ROOT/.git/hooks"

if [ ! -d "$HOOKS_TARGET" ]; then
  echo "Error: .git/hooks directory not found. Are you inside a git repository?"
  exit 1
fi

for hook in "$HOOKS_SOURCE"/*; do
  hook_name=$(basename "$hook")
  target="$HOOKS_TARGET/$hook_name"

  if [ -f "$target" ] && [ ! -L "$target" ]; then
    echo "Backing up existing $hook_name to $hook_name.bak"
    mv "$target" "$target.bak"
  fi

  ln -sf "$REPO_ROOT/hooks/$hook_name" "$target"
  chmod +x "$REPO_ROOT/hooks/$hook_name"
  echo "Installed: $hook_name"
done

echo "Git hooks installed successfully."

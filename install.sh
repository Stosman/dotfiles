#!/usr/bin/env bash
# install.sh
#
# Symlinks every package in this repo into $HOME using GNU Stow.
# Run from inside the repo (or pass a path as $1).
#
# Usage:
#   ./install.sh            # install every package
#   ./install.sh zsh btop   # install only the named packages

set -euo pipefail
cd "$(dirname "$0")"

if ! command -v stow >/dev/null 2>&1; then
  echo "GNU Stow is not installed. On Debian: sudo apt install stow"
  exit 1
fi

if [ "$#" -gt 0 ]; then
  packages=("$@")
else
  packages=()
  for d in */; do
    d="${d%/}"
    [ -d "$d" ] && packages+=("$d")
  done
fi

for pkg in "${packages[@]}"; do
  if [ "$pkg" = "etc" ]; then
    echo "Stowing $pkg into / (needs root) ..."
    sudo stow -v -t / "$pkg"
  else
    echo "Stowing $pkg ..."
    stow -v -t "$HOME" "$pkg"
  fi
done

echo "Done. Re-run with -D instead of the stow call above to unlink."

#!/usr/bin/env bash
# bootstrap-dotfiles.sh
#
# Run this on the machine that holds your real configs (not here).
# Builds a GNU Stow-ready dotfiles repo by copying a curated list of
# files out of $HOME. Caches, logs, histories, and anything secret
# are left out on purpose (see the excluded list at the bottom).
#
# Usage:
#   ./bootstrap-dotfiles.sh [target-repo-dir]
#   defaults to ~/dotfiles

set -euo pipefail

REPO="${1:-$HOME/dotfiles}"
mkdir -p "$REPO"
cd "$REPO"

# package:relative-path-from-HOME pairs
# Add or remove lines here as your setup changes.
FILES=(
  "zsh:.zshrc"
  "bash:.bashrc"
  "bash:.bash_profile"
  "npm:.npmrc"
  "starship:.config/starship.toml"
  "htop:.config/htop/htoprc"
  "micro:.config/micro/bindings.json"
  "micro:.config/micro/settings.json"
  "micro:.config/micro/syntax/ansi.yaml"
  "git:.gitconfig"
  "neofetch:.config/neofetch/config.conf"
  "btop:.config/btop/btop.conf"
  "motd:motd_art"
  "motd:motd1"
  "scripts:scripts"
  "misc:duck.sh"
  "misc:solidfy.py"
)

copied=0
skipped=0

for entry in "${FILES[@]}"; do
  pkg="${entry%%:*}"
  rel="${entry#*:}"
  src="$HOME/$rel"
  dest="$REPO/$pkg/$rel"

  if [ -e "$src" ]; then
    mkdir -p "$(dirname "$dest")"
    cp -a "$src" "$dest"
    echo "  copied  $rel  ->  $pkg/"
    copied=$((copied + 1))
  else
    echo "  skipped $rel (not found on this machine)"
    skipped=$((skipped + 1))
  fi
done

# System-level files under /etc. These go in their own "etc" package,
# mirrored from root rather than $HOME, so the layout matches what
# `stow -t /` expects on restore. Reading /etc is normally fine
# without sudo; writing back to it later is not (see install.sh).
ETC_FILES=(
  "etc/stos/stos-duck.ansi"
  "etc/update-motd.d/99-stos"
)

for rel in "${ETC_FILES[@]}"; do
  src="/$rel"
  dest="$REPO/etc/$rel"

  if [ -e "$src" ]; then
    mkdir -p "$(dirname "$dest")"
    cp -a "$src" "$dest"
    echo "  copied  /$rel  ->  etc/"
    copied=$((copied + 1))
  else
    echo "  skipped /$rel (not found on this machine)"
    skipped=$((skipped + 1))
  fi
done

echo
echo "Done: $copied file(s)/dir(s) copied, $skipped skipped."
echo
echo "Empty package dirs (e.g. micro/btop colorscheme/theme folders" \
     "with nothing custom in them) are safe to delete."
echo
echo "Next steps:"
echo "  cd $REPO"
echo "  git init"
echo "  git add ."
echo "  git commit -m 'Initial dotfiles'"
echo
echo "NOT copied by design (see README.md for why):"
echo "  .ssh/ (contains your private key), .docker/config.json," \
     " .npm cache and logs, .cache, .local (pipx venvs)," \
     " .bash_history, .zsh_history, .lesshst, .zcompdump, .wget-hsts"

#!/usr/bin/env bash
# The "feel the updates" ritual: bump nixpkgs, build the candidate system
# WITHOUT applying it, show the nvd diff of exactly what would change, then let
# you apply it (sudo switch) or revert the lock. Nothing is activated until you
# say yes, so this is safe to run any time.
set -uo pipefail
FLAKE="$HOME/code/nixos-hypr-config"
cd "$FLAKE" || { echo "Can't cd to $FLAKE"; read -rsn1 -p "Press any key…"; exit 1; }

echo "==> nix flake update  (fetching the latest nixpkgs)…"
nix flake update 2>&1 | tail -4

if git diff --quiet -- flake.lock; then
    echo; echo "✓ Already on the latest — flake.lock didn't move. Nothing to update. 🎉"
    echo; read -rsn1 -p "Press any key to close…"; exit 0
fi

echo; echo "==> Building the candidate system (no changes applied yet)…"
if ! nixos-rebuild build --flake ".#hypr-nix"; then
    echo; echo "✗ Build failed — reverting flake.lock."; git checkout -- flake.lock
    echo; read -rsn1 -p "Press any key to close…"; exit 1
fi

echo; echo "════════ What this update would change ════════"; echo
nvd diff /run/current-system ./result
echo

read -rp "Apply this update now (sudo nixos-rebuild switch)? [y/N] " a
if [[ "$a" =~ ^[Yy]$ ]]; then
    sudo nixos-rebuild switch --flake ".#hypr-nix"
    echo; echo "✓ Applied. If you're happy, commit the bump:"
    echo "    git -C $FLAKE add flake.lock && git -C $FLAKE commit -m 'flake update'"
else
    read -rp "Revert the flake.lock bump (undo the fetch)? [Y/n] " r
    if [[ "$r" =~ ^[Nn]$ ]]; then echo "Kept the updated flake.lock (built but not applied)."
    else git checkout -- flake.lock; echo "Reverted flake.lock."; fi
fi
echo; read -rsn1 -p "Press any key to close…"

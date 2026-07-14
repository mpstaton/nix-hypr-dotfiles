#!/usr/bin/env bash
# Waybar module: is this system's pinned nixpkgs behind the nixos-26.05 branch?
# Emits one JSON line: {text, tooltip, class}.
#   class "has-updates" -> nixpkgs branch moved past our lock (updates available)
#   class "updated"     -> lock == branch HEAD (nothing to do)
#   (offline/error      -> empty text, module hides)
# `--open` instead opens a terminal with the update/preview commands.
FLAKE="$HOME/code/nixos-hypr-config"
BRANCH="nixos-26.05"
REPO="https://github.com/NixOS/nixpkgs.git"

if [ "${1:-}" = "--open" ]; then
    # System/update terminal = foot with a distinct maroon tint, so it's
    # visually unmistakable vs the Ghostty dev terminal. Runs the preview ritual
    # (bump -> build -> nvd diff -> apply or revert). footclient is instant
    # (foot --server autostarts); fall back to a standalone foot if needed.
    preview="$HOME/.config/hypr/scripts/nix_update_preview.sh"
    footclient --title "NixOS-update" -o colors.background=2b1a1f -o colors.foreground=e8e0e2 "$preview" 2>/dev/null \
      || foot --title "NixOS-update" -o colors.background=2b1a1f -o colors.foreground=e8e0e2 "$preview"
    exit 0
fi

emit() { printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$1" "$2" "$3"; }

# Resolve the ROOT's nixpkgs node. When another input (e.g. hunk) also has a
# nixpkgs, Nix renames the root's to "nixpkgs_2" and the bare "nixpkgs" node
# becomes that other input's — so hard-coding .nodes.nixpkgs reads the WRONG
# pin. Follow root.inputs.nixpkgs to the real node name.
node=$(jq -r '.nodes.root.inputs.nixpkgs // "nixpkgs"' "$FLAKE/flake.lock" 2>/dev/null)
locked=$(jq -r --arg n "$node" '.nodes[$n].locked.rev // empty' "$FLAKE/flake.lock" 2>/dev/null)
[ -z "$locked" ] && { emit "" "nixpkgs rev not found in flake.lock" "error"; exit 0; }

remote=$(GIT_TERMINAL_PROMPT=0 timeout 8 git ls-remote "$REPO" "$BRANCH" 2>/dev/null | awk 'NR==1{print $1}')
[ -z "$remote" ] && { emit "" "NixOS: offline — can't check $BRANCH" "offline"; exit 0; }

if [ "$locked" = "$remote" ]; then
    emit "󰄬" "NixOS up to date ($BRANCH)" "updated"
    exit 0
fi

# NOTE: we deliberately do NOT show a commit count — nixpkgs branch commits
# (inflated by "staging" merges) are not the same as updates to installed
# packages. The only accurate "what of mine changes" list comes from building
# the candidate and running `nvd`, which the click action does.
emit "󰚰" "Updates available on $BRANCH.\\nClick to build the new system and see exactly which of your installed packages change (nvd)." "has-updates"

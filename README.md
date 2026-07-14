# nix-hypr-dotfiles

Hyprland desktop dotfiles for the `hypr-nix` machine, managed with **GNU Stow**.
Companion to the system config at
[nixos-hypr-config](https://github.com/mpstaton/nixos-hypr-config) — that repo
owns packages/services; this one owns the hand-placed user configs that are
deliberately **not** managed by home-manager.

## Layout — each top dir is a Stow "package" mirroring `$HOME`
```
hypr/.config/hypr/        hyprland.conf + scripts (cheatsheet, layout toggle, screenshots…)
waybar/.config/waybar/    config.jsonc, style.css, scripts
wofi/.config/wofi/        config, style.css
wpaperd/.config/wpaperd/  config.toml
ghostty/.config/ghostty/  config
```

## Usage
```bash
git clone https://github.com/mpstaton/nix-hypr-dotfiles ~/nix-hypr-dotfiles
cd ~/nix-hypr-dotfiles
stow */          # symlink every package into ~/.config  (or: stow waybar)
```
`~/.config/<app>` become symlinks into this repo, so editing a live config
edits the repo — commit from here. Remove a package's links with `stow -D <pkg>`.

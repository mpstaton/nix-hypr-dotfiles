#!/usr/bin/env bash
# Toggle Hyprland's global layout between dwindle and master.
#   master = one full-height window on the side (the "master"), the rest
#            stacked beside it. Great for "main window + reference windows".
#   dwindle = the default recursive splits.
cur=$(hyprctl getoption general:layout -j | jq -r '.str')
if [ "$cur" = "master" ]; then
    hyprctl keyword general:layout dwindle >/dev/null
    notify-send -t 1400 "Layout: dwindle" "Standard recursive splits"
else
    hyprctl keyword general:layout master >/dev/null
    notify-send -t 1400 "Layout: master" "Focused = full-height master; others stack to the side (Super+Shift+M promotes the focused window)"
fi

#!/usr/bin/env bash
# Keybinding cheat-sheet for Hyprland — human-readable.
# Reads LIVE binds from `hyprctl binds` and translates each into plain English,
# then shows a searchable wofi list. If a bind has its own description (set via
# `bindd=` in the config), that is used instead of the built-in translation.
set -euo pipefail

# Decode Hyprland's modmask bitmask -> readable names.
modname() {
    local m=$1 out=""
    (( m & 64 )) && out+="SUPER+"
    (( m & 4 ))  && out+="CTRL+"
    (( m & 8 ))  && out+="ALT+"
    (( m & 1 ))  && out+="SHIFT+"
    printf '%s' "${out%+}"
}

# Raw keycode -> friendly key label (for binds with no named key, e.g. media keys).
keyname() {
    case "$1" in
        121) echo "Mute";; 122) echo "VolDown";; 123) echo "VolUp";;
        232) echo "BrightDown";; 233) echo "BrightUp";;
        171) echo "Next";; 172) echo "Play/Pause";; 173) echo "Prev";;
        65) echo "Space";; 0) echo "";; *) echo "code-$1";;
    esac
}

# exec commands -> what they actually do (most specific patterns first).
describe_exec() {
    case "$1" in
        *keybind_cheatsheet*)          echo "Show this keybindings cheat-sheet" ;;
        *"--show drun"*|*"pkill wofi"*) echo "App launcher — type the app name (wofi)" ;;
        *toggle_layout*)               echo "Toggle layout: dwindle <-> master" ;;
        *hyprshot*satty*)              echo "Screenshot a region, then annotate it (satty)" ;;
        *hyprshot*window*)             echo "Screenshot a window" ;;
        *hyprshot*output*)             echo "Screenshot the whole monitor" ;;
        *hyprshot*region*)             echo "Screenshot a selected region" ;;
        *"hyprctl reload"*)            echo "Reload the Hyprland config" ;;
        *nwg-drawer*)                  echo "Open the full app launcher (grid)" ;;
        *nwgbar*)                      echo "Open the power / session menu" ;;
        *cliphist*)                    echo "Clipboard history picker" ;;
        *pamixer*increase*)            echo "Volume up" ;;
        *pamixer*decrease*)            echo "Volume down" ;;
        *pamixer*toggle-mute*)         echo "Toggle speaker mute" ;;
        *pactl*)                       echo "Toggle microphone mute" ;;
        *brightnessctl*"set +"*)       echo "Screen brightness up" ;;
        *brightnessctl*)               echo "Screen brightness down" ;;
        *play-pause*)                  echo "Play / pause media" ;;
        *"playerctl next"*)            echo "Next track" ;;
        *"playerctl previous"*)        echo "Previous track" ;;
        *wpaperd*)                     echo "Change the wallpaper" ;;
        *nmtui*|*nmcli*)               echo "Network settings (nmtui)" ;;
        firefox*)                      echo "Launch Firefox" ;;
        thunar*)                       echo "Open the file manager" ;;
        thunderbird*)                  echo "Launch Thunderbird (mail)" ;;
        geany*)                        echo "Launch Geany (editor)" ;;
        gitkraken*)                    echo "Launch GitKraken" ;;
        gparted*)                      echo "Launch GParted" ;;
        inkscape*)                     echo "Launch Inkscape" ;;
        blender*)                      echo "Launch Blender" ;;
        meld*)                         echo "Launch Meld (diff tool)" ;;
        joplin*)                       echo "Launch Joplin (notes)" ;;
        galculator*)                   echo "Launch the calculator" ;;
        *fullscreen*kitty*|kitty*fullscreen*) echo "Open a fullscreen terminal" ;;
        kitty*|foot*)                  echo "Open a terminal" ;;
        wofi*)                         echo "App launcher (wofi)" ;;
        *)                             echo "Run: ${1:0:48}" ;;
    esac
}

# dispatcher + arg -> plain English.
describe() {
    local disp="$1" arg="$2"
    case "$disp" in
        movefocus)   case "$arg" in l) echo "Focus the window to the LEFT";; r) echo "Focus the window to the RIGHT";; u) echo "Focus the window ABOVE";; d) echo "Focus the window BELOW";; *) echo "Move focus $arg";; esac ;;
        movewindow)  case "$arg" in l) echo "Move window LEFT";; r) echo "Move window RIGHT";; u) echo "Move window UP";; d) echo "Move window DOWN";; *) echo "Move window (drag with mouse)";; esac ;;
        resizewindow) echo "Resize window (drag with mouse)" ;;
        resizeactive) case "$arg" in "50 0") echo "Make window WIDER";; "-50 0") echo "Make window NARROWER";; "0 50") echo "Make window TALLER";; "0 -50") echo "Make window SHORTER";; *) echo "Resize window ($arg)";; esac ;;
        workspace)   case "$arg" in e+1) echo "Go to the NEXT workspace";; e-1) echo "Go to the PREVIOUS workspace";; *) echo "Switch to workspace $arg";; esac ;;
        movetoworkspace)       echo "Move window to workspace $arg (and follow it)" ;;
        movetoworkspacesilent) echo "Send window to workspace $arg (stay here)" ;;
        swapactiveworkspaces)  echo "Swap the workspaces between the two monitors" ;;
        killactive)      echo "Close the focused window" ;;
        togglefloating)  echo "Toggle window floating / tiled" ;;
        fullscreen)      case "$arg" in 0) echo "Fullscreen (cover everything)";; 1) echo "Maximize (fill screen, keep bar + gaps)";; *) echo "Fullscreen $arg";; esac ;;
        fullscreenstate) echo "Fake-fullscreen (fills space, not true fullscreen)" ;;
        pseudo)      echo "Toggle pseudo-tiling" ;;
        layoutmsg)   case "$arg" in togglesplit) echo "Flip the split: side-by-side <-> stacked";; swapwithmaster) echo "Make focused window the full-height MASTER";; *) echo "Layout action: $arg";; esac ;;
        submap)      case "$arg" in resize) echo "Enter RESIZE mode (then use arrows / HJKL)";; reset) echo "Leave resize mode";; *) echo "Enter mode: $arg";; esac ;;
        exec)        describe_exec "$arg" ;;
        *)           echo "$disp${arg:+ $arg}" ;;
    esac
}

build() {
    # 0x1F delimiter so empty fields (keycode-only binds) don't collapse columns.
    hyprctl binds -j | jq -r '.[] | [(.modmask|tostring), .key, (.keycode|tostring), .submap, .dispatcher, .description, .arg] | join("\u001f")' |
    while IFS=$'\x1f' read -r mask key keycode submap disp descr arg; do
        # mouse binds
        case "$key" in
            mouse:272) combo="$(modname "$mask")+drag-L"; text="Move window by dragging"; printf '%-24s   %s\n' "$combo" "$text"; continue ;;
            mouse:273) combo="$(modname "$mask")+drag-R"; text="Resize window by dragging"; printf '%-24s   %s\n' "$combo" "$text"; continue ;;
        esac
        [ -z "$key" ] && key=$(keyname "$keycode")
        [ -z "$key" ] && continue
        mods=$(modname "$mask")
        combo="${mods:+$mods+}$key"
        if [ -n "$descr" ]; then text="$descr"; else text=$(describe "$disp" "$arg"); fi
        [ -n "$submap" ] && text="(resize mode) $text"
        text=${text//&/and}
        printf '%-24s   %s\n' "$combo" "$text"
    done
}

# Sort by the description (field 2+) so related actions group together.
if [ "${1:-}" = "--dry-run" ]; then
    build | sort -k2
    exit 0
fi

build | sort -k2 | wofi --dmenu --insensitive --lines 26 --width 1200 --prompt "Keybindings" >/dev/null || true

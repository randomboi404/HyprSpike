#!/bin/bash

WALL_DIR="$HOME/Pictures/Wallpapers"

CWD="$(pwd)"

cd "$WALL_DIR" || exit 1

IFS=$'\n'

SELECTED_WALL=$(for a in *.jpg *.png; do echo -en "$a\0icon\x1f$a\n" ; done | rofi -dmenu -p "Wallpaper")

if [ -n "$SELECTED_WALL" ]; then
  $HOME/.local/bin/theme-switcher.sh "$SELECTED_WALL"
fi

cd "$CWD" || exit

#!/bin/bash

# Config
CONFIG="$HOME/.config/hyprlock/layouts/layout2/hyprlock.conf"
WALLPAPER_DIR="$HOME/.config/RamOS/Wallpapers/wallpaper.png"

# start songdetail to get the song info and album art
bash $HOME/.config/hyprlock/layouts/layout2/Scripts/nowplaying/nowplaying.sh

# start hyprlock

hyprlock -c .config/hyprlock/layouts/layout2/hyprlock.conf




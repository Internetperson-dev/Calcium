#!/bin/bash

#####################################
## Author: Harsh-bin (modified) #####
## Uses ffmpeg instead of magick ####
#####################################

# --- Configuration ---
art_file="$HOME/.config/hyprlock/layouts/layout2/Scripts/nowplaying/album_art.jpg"
fallback_art_file="$HOME/.config/hyprlock/layouts/layout2/Scripts/nowplaying/fallback_album_art.jpg"
cache_file="$HOME/.config/hypr/nowplaying/song_title.cache"
debug_file="/tmp/song_debug.txt"

echo "[DEBUG] Starting script" > "$debug_file"

# --- Functions ---
escape_characters() {
    echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
}

url_decode() {
    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}

# --- Determine active player ---
players_list=$(playerctl -l 2>/dev/null)
active_player=""
active_player_priority=0 

while IFS= read -r player; do
    if [ -z "$player" ]; then continue; fi

    status=$(playerctl -p "$player" status 2>/dev/null | tr '[:upper:]' '[:lower:]')
    title=$(playerctl -p "$player" metadata title 2>/dev/null)

    current_priority=0
    if [ "$status" == "playing" ]; then
        current_priority=3
    elif [ "$status" == "paused" ]; then
        current_priority=2
    elif [ -n "$title" ]; then
        current_priority=1
    fi

    if [ "$current_priority" -gt "$active_player_priority" ]; then
        active_player="$player"
        active_player_priority=$current_priority
    fi
done <<< "$players_list"

echo "[DEBUG] Active player: $active_player" >> "$debug_file"

# --- Exit if no player ---
if [[ -z "$active_player" ]]; then
    echo "[DEBUG] No active player, cleaning art" >> "$debug_file"
    rm "$art_file" 2>/dev/null
    rm "$cache_file" 2>/dev/null
    echo "No media"
    exit 0
fi

# --- Handle play/pause toggle ---
if [[ "$1" == "--toggle" ]]; then
    if [[ -n "$active_player" ]]; then
        playerctl -p "$active_player" play-pause    
    fi
    exit 0
fi

# --- Fetch metadata ---
raw_title=$(playerctl -p "$active_player" metadata title 2>/dev/null)
raw_artist=$(playerctl -p "$active_player" metadata artist 2>/dev/null)
status=$(playerctl -p "$active_player" status 2>/dev/null)
album_art_url=$(playerctl -p "$active_player" metadata mpris:artUrl 2>/dev/null)

echo "[DEBUG] Title: $raw_title" >> "$debug_file"
echo "[DEBUG] Artist: $raw_artist" >> "$debug_file"
echo "[DEBUG] Status: $status" >> "$debug_file"
echo "[DEBUG] Art URL: $album_art_url" >> "$debug_file"

# --- Escape characters ---
clean_name="${active_player%%.*}" 
clean_name="$(tr '[:lower:]' '[:upper:]' <<< ${clean_name:0:1})${clean_name:1}"
player_display_name=$(escape_characters "$clean_name")   
song_title=$(escape_characters "$raw_title")
song_artist=$(escape_characters "$raw_artist")

# --- Update album art ---
cached_title=""
if [[ -f "$cache_file" ]]; then
    cached_title=$(cat "$cache_file")
fi

if [[ "$raw_title" != "$cached_title" ]] || [[ ! -f "$art_file" ]]; then
    echo "$raw_title" > "$cache_file"

    if [[ -z "$album_art_url" ]]; then
        echo "[DEBUG] No album art URL, using fallback" >> "$debug_file"
        cp "$fallback_art_file" "$art_file" 2>/dev/null
    elif [[ "$album_art_url" =~ ^data:image ]]; then
        echo "[DEBUG] Base64 album art detected" >> "$debug_file"
        base64_data=$(echo "$album_art_url" | cut -d',' -f2)
        echo "$base64_data" | base64 -d > "$art_file" 2>/dev/null
    elif [[ "$album_art_url" =~ ^file:// ]]; then
        echo "[DEBUG] File album art detected" >> "$debug_file"
        raw_path="${album_art_url#file://}"
        decoded_path="$(url_decode "$raw_path")"
        echo "[DEBUG] Decoded path: $decoded_path" >> "$debug_file"
        if [[ -f "$decoded_path" ]]; then
            ffmpeg -y -i "$decoded_path" \
                -vf "scale='if(gt(iw,400),400,iw)':'if(gt(ih,400),400,ih)'" \
                -q:v 2 "$art_file" < /dev/null >/dev/null 2>&1
        fi
    elif [[ "$album_art_url" =~ ^https:// ]]; then
        echo "[DEBUG] Web album art detected" >> "$debug_file"
        tmp_file=$(mktemp)
        curl -s "$album_art_url" -o "$tmp_file"
        ffmpeg -y -i "$tmp_file" \
            -vf "scale='if(gt(iw,400),400,iw)':'if(gt(ih,400),400,ih)'" \
            -q:v 2 "$art_file" < /dev/null >/dev/null 2>&1
        rm -f "$tmp_file"
    fi

    if [[ -f "$art_file" ]]; then
        echo "[DEBUG] ART exists after conversion: yes" >> "$debug_file"
    else
        echo "[DEBUG] ART exists after conversion: no" >> "$debug_file"
    fi
fi

# --- Determine play status icon ---
if [[ "$status" == "Playing" ]]; then
    player_status="▶"
else
    player_status="⏸"
fi

# --- Output for Hyprlock ---
echo -e "<span font_weight='light' size='small' alpha='80%'>${player_display_name} <small>${player_status}</small></span>\n<b>${song_title}</b>    <span alpha='80%' style='italic'>${song_artist}</span>"

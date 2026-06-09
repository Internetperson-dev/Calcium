#!/bin/bash

# Directory containing AppImages
APPIMAGE_DIR="$HOME/.local/bin"   # Change this if needed
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons"

mkdir -p "$DESKTOP_DIR"
mkdir -p "$ICON_DIR"

for app in "$APPIMAGE_DIR"/*.AppImage; do
    [ -e "$app" ] || continue

    filename=$(basename "$app")
    name="${filename%%.AppImage}"
    desktop_file="$DESKTOP_DIR/$name.desktop"
    icon_path="$ICON_DIR/$name.png"

    echo "Processing: $filename"

    # Try to extract the icon
    if [[ ! -f "$icon_path" ]]; then
        echo "Extracting icon..."
        tmpdir=$(mktemp -d)
        chmod +x "$app"
        "$app" --appimage-extract > /dev/null 2>&1
        if [[ -d squashfs-root ]]; then
            find squashfs-root -type f \( -name "*.png" -o -name "*.svg" \) | while read -r icon; do
                if [[ "$icon" == *"256x256"* || "$icon" == *"/hicolor/"* ]]; then
                    cp "$icon" "$icon_path" && break
                fi
            done
            rm -rf squashfs-root
        fi
        rm -rf "$tmpdir"
    fi

    # Create .desktop file
    cat > "$desktop_file" <<EOF
[Desktop Entry]
Name=$name
Exec="$app"
Icon=$name
Type=Application
Categories=Utility;
StartupNotify=true
Terminal=false
EOF

    chmod +x "$desktop_file"
    echo "Created desktop entry: $desktop_file"
done

echo "All done."

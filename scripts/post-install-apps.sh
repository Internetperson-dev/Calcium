#!/bin/bash
# Post-install script for AppImages and Flatpaks
# Run this on your target system after booting the ISO
#
# Usage: bash post-install-apps.sh [install|list]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APPIMAGE_LIST="$SCRIPT_DIR/appimage.list"
FLATPAK_LIST="$SCRIPT_DIR/flatpak.list"

list_appimages() {
    echo "=== AppImages from source system ==="
    if [ -f "$APPIMAGE_LIST" ]; then
        cat "$APPIMAGE_LIST"
    else
        echo "No appimage.list found in $SCRIPT_DIR"
    fi
}

list_flatpaks() {
    echo "=== Flatpaks from source system ==="
    if [ -f "$FLATPAK_LIST" ]; then
        cat "$FLATPAK_LIST"
    else
        echo "No flatpak.list found in $SCRIPT_DIR"
    fi
}

install_flatpaks() {
    if ! command -v flatpak &>/dev/null; then
        echo "Flatpak not installed. Install it with: emerge -q sys-apps/flatpak"
        return 1
    fi

    if ! flatpak remote-list 2>/dev/null | grep -q flathub; then
        echo "Adding Flathub remote..."
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    fi

    if [ -f "$FLATPAK_LIST" ]; then
        echo "Installing Flatpaks..."
        while IFS= read -r app; do
            [ -z "$app" ] && continue
            echo "  Installing: $app"
            flatpak install -y flathub "$app"
        done < "$FLATPAK_LIST"
    fi
}

install_appimages() {
    local target="${1:-$HOME/.local/appimage}"
    mkdir -p "$target"

    if [ -f "$APPIMAGE_LIST" ]; then
        echo "AppImages from source system (download manually):"
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            # Format: name|url
            name="${line%%|*}"
            url="${line#*|}"
            if [ -n "$url" ] && [ "$name" != "$url" ]; then
                echo "  $name -> $url"
            else
                echo "  $name"
            fi
        done < "$APPIMAGE_LIST"
    fi
}

case "${1:-list}" in
    list)
        list_appimages
        echo
        list_flatpaks
        ;;
    install)
        install_flatpaks
        install_appimages
        ;;
    *)
        echo "Usage: $0 [list|install]"
        exit 1
        ;;
esac

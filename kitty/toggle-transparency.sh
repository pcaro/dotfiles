#!/bin/bash

# Path to the Kitty configuration file
KITTY_CONFIG="$HOME/.config/kitty/kitty.conf"

# Target file for editing. Allow symbolic links
TARGET_FILE=$(readlink -f "$KITTY_CONFIG")

# Dynamically locate Kitty's socket in ~/.config/kitty (handling random suffixes)
KITTY_SOCKET=$(find "/tmp" -type s -name 'kitty-*' 2>/dev/null | head -n 1)

# Check if the socket exists
if [[ -z "$KITTY_SOCKET" ]] || [[ ! -S "$KITTY_SOCKET" ]]; then
    echo "Error: Kitty's socket file not found. Make sure Kitty is running."
    exit 1
fi

# Check the current background_opacity value in the config
if grep -q "background_opacity 1.0" "$TARGET_FILE"; then
    # Switch to transparency (set to 0.9)
    sed -i 's/background_opacity 1.0/background_opacity 0.95/' "$TARGET_FILE"
    echo "Transparency enabled (background_opacity set to 0.95)."
else
    # Switch to opaque (set to 1.0)
    sed -i 's/background_opacity 0.95/background_opacity 1.0/' "$TARGET_FILE"
    echo "Transparency disabled (background_opacity set to 1.0)."
fi

# Reload Kitty's configuration using the dynamically identified socket
if ! kitty @ --to=unix:"$KITTY_SOCKET" load-config; then
    echo "Failed to reload Kitty. Please manually reload with Ctrl+Shift+F5."
    exit 1
fi

exit 0

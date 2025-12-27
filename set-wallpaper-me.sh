#!/bin/bash

# Wallpaper setter script for macOS
# Downloads an image from imgbox and sets it as wallpaper

# Configuration
IMAGE_URL="https://images2.imgbox.com/21/0a/krMCqhVu_o.jpg"
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
FILENAME="space_wallpaper.jpg"
FILEPATH="$WALLPAPER_DIR/$FILENAME"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_message() {
    echo -e "${2}${1}${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Create Wallpapers directory if it doesn't exist
print_message "Creating Wallpapers directory..." "$YELLOW"
mkdir -p "$WALLPAPER_DIR"

# Download the image
print_message "Downloading wallpaper from imgbox..." "$YELLOW"
if command_exists "curl"; then
    curl -L -o "$FILEPATH" "$IMAGE_URL"
elif command_exists "wget"; then
    wget -O "$FILEPATH" "$IMAGE_URL"
else
    print_message "Error: Neither curl nor wget found. Please install one of them." "$RED"
    exit 1
fi

# Check if download was successful
if [ ! -f "$FILEPATH" ]; then
    print_message "Error: Failed to download the image." "$RED"
    exit 1
fi

# Check file size to ensure it's not empty
if [ ! -s "$FILEPATH" ]; then
    print_message "Error: Downloaded file is empty." "$RED"
    rm "$FILEPATH"
    exit 1
fi

print_message "Download completed successfully!" "$GREEN"
print_message "Image saved to: $FILEPATH" "$GREEN"

# Set as wallpaper using AppleScript
print_message "Setting as wallpaper..." "$YELLOW"

# Determine which version of macOS we're running
if osascript -e 'tell application "System Events" to get name of every desktop' >/dev/null 2>&1; then
    # For newer macOS versions (multiple desktops/spaces)
    osascript <<EOF
tell application "System Events"
    set allDesktops to every desktop
    repeat with currentDesktop in allDesktops
        set picture of currentDesktop to "$FILEPATH"
    end repeat
end tell
EOF
    print_message "Wallpaper set successfully on all desktops!" "$GREEN"
else
    # For older macOS versions (fallback method)
    osascript <<EOF
tell application "Finder"
    set desktop picture to POSIX file "$FILEPATH"
end tell
EOF
    print_message "Wallpaper set successfully!" "$GREEN"
fi

# Optional: Also set via sqlite3 for persistent setting across restarts
if command_exists "sqlite3"; then
    print_message "Making wallpaper setting persistent..." "$YELLOW"
    
    # Find the database file (location varies by macOS version)
    DB_FILE="$HOME/Library/Application Support/Dock/desktoppicture.db"
    
    if [ -f "$DB_FILE" ]; then
        # Backup the original database
        cp "$DB_FILE" "${DB_FILE}.backup"
        
        # Update the database
        sqlite3 "$DB_FILE" "UPDATE data SET value = '$FILEPATH';" 2>/dev/null
        
        # Kill Dock to apply changes
        killall Dock 2>/dev/null
        
        print_message "Persistent wallpaper setting applied!" "$GREEN"
    fi
fi

print_message "✓ Wallpaper has been set successfully!" "$GREEN"
print_message "The image is saved at: $FILEPATH" "$GREEN"
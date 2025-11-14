#!/bin/bash
# Example script to execute Minecraft commands via screen session
# Usage: ./execute-command.sh "say Hello World"

SCREEN_NAME="minecraft"

# Find the actual screen session name (handles cases like "123.minecraft")
SCREEN_SESSION=$(screen -list | grep -i minecraft | head -1 | awk '{print $1}' | cut -d'.' -f2-)

if [ -z "$SCREEN_SESSION" ]; then
    echo "Error: No Minecraft screen session found"
    exit 1
fi

# Get the command from arguments
COMMAND="${1}"

if [ -z "$COMMAND" ]; then
    echo "Usage: $0 \"<minecraft command>\""
    echo "Example: $0 \"say Hello World\""
    echo "Example: $0 \"give @a minecraft:diamond 1\""
    exit 1
fi

# Send command to screen session
# screen -X stuff sends the command, and \n simulates pressing Enter
screen -S "$SCREEN_SESSION" -X stuff "$COMMAND"$'\n'

echo "Command sent: $COMMAND"


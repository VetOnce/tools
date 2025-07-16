#!/bin/bash

# Script to open Railway log monitor in a new terminal window

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Opening Railway Control Terminal...${NC}"

# Change to project directory for Railway context
cd "$PROJECT_ROOT"

# Detect the operating system and terminal
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    if command -v osascript &> /dev/null; then
        # Check if Terminal.app is running
        if osascript -e 'tell application "System Events" to (name of processes) contains "Terminal"' | grep -q "true"; then
            # Open in new Terminal window
            osascript <<EOF
tell application "Terminal"
    do script "cd '$PROJECT_ROOT' && '$SCRIPT_DIR/railway-logs.sh'"
    activate
end tell
EOF
        else
            # Terminal not running, use open command
            open -a Terminal "$SCRIPT_DIR/railway-logs.sh"
        fi
        
        echo -e "${GREEN}Railway Control Terminal opened in new window${NC}"
    else
        echo -e "${YELLOW}Cannot open new terminal window, running in current terminal...${NC}"
        "$SCRIPT_DIR/railway-logs.sh"
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    if command -v gnome-terminal &> /dev/null; then
        gnome-terminal -- bash -c "cd '$PROJECT_ROOT' && '$SCRIPT_DIR/railway-logs.sh'; exec bash"
    elif command -v xterm &> /dev/null; then
        xterm -e "cd '$PROJECT_ROOT' && '$SCRIPT_DIR/railway-logs.sh'" &
    elif command -v konsole &> /dev/null; then
        konsole -e "cd '$PROJECT_ROOT' && '$SCRIPT_DIR/railway-logs.sh'" &
    else
        echo -e "${YELLOW}No supported terminal found, running in current terminal...${NC}"
        "$SCRIPT_DIR/railway-logs.sh"
    fi
else
    # Fallback for other systems
    echo -e "${YELLOW}Unsupported OS, running in current terminal...${NC}"
    "$SCRIPT_DIR/railway-logs.sh"
fi
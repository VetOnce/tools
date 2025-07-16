# Cursor Window Controller

A Python-based tool for monitoring and controlling Cursor application windows on macOS.

## Features

- List all open Cursor windows with their titles, positions, and sizes
- Monitor windows in real-time for changes
- Control windows: focus, minimize, unminimize, close
- Move and resize windows programmatically
- Simple command-line interface
- Terminal monitoring for Claude 4 detection
- Automatic option selection (chooses option 2 when 1,2,3 menu appears)
- GUI interface for visual control

## Prerequisites

### Enable Assistive Access

This tool requires assistive access permissions to control windows. To enable:

1. Open **System Preferences** > **Security & Privacy** > **Privacy**
2. Select **Accessibility** from the left panel
3. Click the lock icon to make changes
4. Add **Terminal** (or your terminal application) to the list
5. Ensure the checkbox next to Terminal is checked

## Installation

1. Clone or download this repository
2. No additional dependencies required - uses built-in Python and macOS AppleScript

## Usage

```bash
python3 cursor-window-monitor.py <command> [args]
```

### Commands

- `list` - List all Cursor windows with their details
- `monitor [seconds]` - Monitor windows for changes (default: 1 second interval)
- `focus <index>` - Bring a specific window to focus
- `minimize <index>` - Minimize a window
- `unminimize <index>` - Restore a minimized window
- `close <index>` - Close a window
- `move <index> <x> <y>` - Move a window to specific coordinates
- `resize <index> <width> <height>` - Resize a window

### Examples

```bash
# List all windows
python3 cursor-window-monitor.py list

# Monitor windows with 2-second interval
python3 cursor-window-monitor.py monitor 2

# Focus window 1
python3 cursor-window-monitor.py focus 1

# Move window 2 to position (100, 100)
python3 cursor-window-monitor.py move 2 100 100

# Resize window 1 to 1200x800
python3 cursor-window-monitor.py resize 1 1200 800
```

## Output Format

### List Command
```
Found 3 Cursor window(s):

Window 1: Cursor [📗 Active]
  Position: [255, 156]
  Size: [1200, 800]

Window 2: project-file.py [📗 Active]
  Position: [0, 43]
  Size: [1710, 1069]

Window 3: README.md [📕 Minimized]
  Position: [0, 43]
  Size: [1710, 1069]
```

### Monitor Command
```
Monitoring Cursor windows (checking every 1 seconds)...
Press Ctrl+C to stop

[14:32:15] Window state changed:
  📗 Window 1: Cursor
     Position: [255, 156]
     Size: [1200, 800]
  📗 Window 2: project-file.py
     Position: [0, 43]
     Size: [1710, 1069]
```

## Terminal Monitoring

### cursor-terminal-monitor.py

Monitors Cursor windows for Claude 4 and automatically selects option 2:

```bash
# Start monitoring
python3 cursor-terminal-monitor.py

# Run diagnostic to see what's detected
python3 cursor-terminal-monitor.py diagnostic
```

### cursor-terminal-ocr.py

Advanced version using OCR for more reliable terminal content detection:

```bash
# Start OCR monitoring
python3 cursor-terminal-ocr.py

# Run diagnostic
python3 cursor-terminal-ocr.py diagnostic

# Test mode (single pass)
python3 cursor-terminal-ocr.py test
```

The OCR version:
- Takes screenshots of windows
- Uses macOS Vision framework for text recognition
- Detects "Claude 4" or "Opus 4" in terminal content
- Automatically types "2" and presses Enter when option menu is detected

## GUI Interface

### cursor-gui.py

Visual interface for window management:

```bash
python3 cursor-gui.py
```

Features:
- Real-time window list with status indicators
- Click to select windows
- Buttons for all window actions
- Position and size adjustment controls
- Toggle monitoring on/off

## How It Works

The tool uses macOS's AppleScript via the `osascript` command to interact with the System Events API. This allows it to:

- Query window properties (title, position, size, minimized state)
- Perform window actions (focus, minimize, close, move, resize)
- Monitor changes in real-time
- Capture screenshots and perform OCR for terminal content detection
- Simulate keyboard input for automatic option selection

## Limitations

- Requires macOS (uses AppleScript)
- Requires assistive access permissions
- Window indices may change when windows are opened/closed
- Some window properties may not be accessible for certain window types

## Troubleshooting

### "osascript is not allowed assistive access" Error

This means Terminal doesn't have the required permissions. Follow the Prerequisites section to enable assistive access.

### "Cursor is not running" Message

Make sure the Cursor application is open before running the commands.

### Window Index Issues

Window indices start at 1 and may change as windows are opened/closed. Always run `list` first to get current indices.
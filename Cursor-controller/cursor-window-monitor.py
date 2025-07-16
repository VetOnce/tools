#!/usr/bin/env python3
"""
Cursor Window Monitor and Controller

This script monitors and controls Cursor application windows on macOS.
Requires assistive access permissions for Terminal/Python.
"""

import subprocess
import json
import time
import sys
from datetime import datetime


class CursorWindowManager:
    def __init__(self):
        self.app_name = "Cursor"
    
    def run_osascript(self, script):
        """Execute AppleScript and return the result."""
        try:
            result = subprocess.run(
                ['osascript', '-e', script],
                capture_output=True,
                text=True,
                check=True
            )
            return result.stdout.strip()
        except subprocess.CalledProcessError as e:
            if "assistive access" in e.stderr:
                print("\n⚠️  ERROR: Assistive access required!")
                print("Please enable assistive access for Terminal:")
                print("1. Open System Preferences > Security & Privacy > Privacy")
                print("2. Select 'Accessibility' from the left panel")
                print("3. Click the lock to make changes")
                print("4. Add Terminal (or your terminal app) to the list")
                print("5. Ensure the checkbox is checked")
                sys.exit(1)
            return None
    
    def is_cursor_running(self):
        """Check if Cursor is running."""
        script = 'tell application "System Events" to (name of processes) contains "Cursor"'
        result = self.run_osascript(script)
        return result == "true"
    
    def get_window_count(self):
        """Get the number of Cursor windows."""
        script = f'tell application "System Events" to tell process "{self.app_name}" to count windows'
        result = self.run_osascript(script)
        return int(result) if result and result.isdigit() else 0
    
    def get_window_info(self, window_index):
        """Get information about a specific window."""
        info = {}
        
        # Get window title
        script = f'tell application "System Events" to tell process "{self.app_name}" to get name of window {window_index}'
        info['title'] = self.run_osascript(script) or "Unknown"
        
        # Get window position
        script = f'tell application "System Events" to tell process "{self.app_name}" to get position of window {window_index}'
        pos = self.run_osascript(script)
        if pos:
            info['position'] = [int(x) for x in pos.split(", ")]
        
        # Get window size
        script = f'tell application "System Events" to tell process "{self.app_name}" to get size of window {window_index}'
        size = self.run_osascript(script)
        if size:
            info['size'] = [int(x) for x in size.split(", ")]
        
        # Check if window is minimized
        script = f'tell application "System Events" to tell process "{self.app_name}" to get value of attribute "AXMinimized" of window {window_index}'
        info['minimized'] = self.run_osascript(script) == "true"
        
        return info
    
    def list_all_windows(self):
        """List all Cursor windows with their information."""
        if not self.is_cursor_running():
            print("Cursor is not running.")
            return []
        
        window_count = self.get_window_count()
        if window_count == 0:
            print("No Cursor windows found.")
            return []
        
        windows = []
        for i in range(1, window_count + 1):
            window_info = self.get_window_info(i)
            window_info['index'] = i
            windows.append(window_info)
        
        return windows
    
    def focus_window(self, window_index):
        """Bring a specific window to focus."""
        script = f'''
        tell application "System Events"
            tell process "{self.app_name}"
                set frontmost to true
                click window {window_index}
            end tell
        end tell
        '''
        self.run_osascript(script)
        print(f"Focused window {window_index}")
    
    def minimize_window(self, window_index):
        """Minimize a specific window."""
        script = f'''
        tell application "System Events"
            tell process "{self.app_name}"
                set value of attribute "AXMinimized" of window {window_index} to true
            end tell
        end tell
        '''
        self.run_osascript(script)
        print(f"Minimized window {window_index}")
    
    def unminimize_window(self, window_index):
        """Unminimize a specific window."""
        script = f'''
        tell application "System Events"
            tell process "{self.app_name}"
                set value of attribute "AXMinimized" of window {window_index} to false
            end tell
        end tell
        '''
        self.run_osascript(script)
        print(f"Unminimized window {window_index}")
    
    def close_window(self, window_index):
        """Close a specific window."""
        script = f'''
        tell application "System Events"
            tell process "{self.app_name}"
                click button 1 of window {window_index}
            end tell
        end tell
        '''
        self.run_osascript(script)
        print(f"Closed window {window_index}")
    
    def move_window(self, window_index, x, y):
        """Move a window to a specific position."""
        script = f'''
        tell application "System Events"
            tell process "{self.app_name}"
                set position of window {window_index} to {{{x}, {y}}}
            end tell
        end tell
        '''
        self.run_osascript(script)
        print(f"Moved window {window_index} to ({x}, {y})")
    
    def resize_window(self, window_index, width, height):
        """Resize a window."""
        script = f'''
        tell application "System Events"
            tell process "{self.app_name}"
                set size of window {window_index} to {{{width}, {height}}}
            end tell
        end tell
        '''
        self.run_osascript(script)
        print(f"Resized window {window_index} to {width}x{height}")
    
    def monitor_windows(self, interval=1):
        """Monitor windows and report changes."""
        print(f"Monitoring Cursor windows (checking every {interval} seconds)...")
        print("Press Ctrl+C to stop\n")
        
        previous_state = []
        
        try:
            while True:
                current_windows = self.list_all_windows()
                
                # Check for changes
                if current_windows != previous_state:
                    timestamp = datetime.now().strftime("%H:%M:%S")
                    print(f"\n[{timestamp}] Window state changed:")
                    
                    # Display current windows
                    for window in current_windows:
                        status = "📗" if not window.get('minimized') else "📕"
                        print(f"  {status} Window {window['index']}: {window['title']}")
                        print(f"     Position: {window.get('position', 'Unknown')}")
                        print(f"     Size: {window.get('size', 'Unknown')}")
                    
                    previous_state = current_windows.copy()
                
                time.sleep(interval)
                
        except KeyboardInterrupt:
            print("\nMonitoring stopped.")


def main():
    manager = CursorWindowManager()
    
    if len(sys.argv) < 2:
        print("Cursor Window Monitor and Controller")
        print("=" * 40)
        print("\nUsage:")
        print("  python cursor-window-monitor.py <command> [args]")
        print("\nCommands:")
        print("  list              - List all Cursor windows")
        print("  monitor [seconds] - Monitor windows for changes")
        print("  focus <index>     - Focus a specific window")
        print("  minimize <index>  - Minimize a window")
        print("  unminimize <index>- Unminimize a window")
        print("  close <index>     - Close a window")
        print("  move <index> <x> <y> - Move a window")
        print("  resize <index> <w> <h> - Resize a window")
        return
    
    command = sys.argv[1].lower()
    
    if command == "list":
        windows = manager.list_all_windows()
        if windows:
            print(f"\nFound {len(windows)} Cursor window(s):")
            for window in windows:
                status = "📗 Active" if not window.get('minimized') else "📕 Minimized"
                print(f"\nWindow {window['index']}: {window['title']} [{status}]")
                print(f"  Position: {window.get('position', 'Unknown')}")
                print(f"  Size: {window.get('size', 'Unknown')}")
    
    elif command == "monitor":
        interval = int(sys.argv[2]) if len(sys.argv) > 2 else 1
        manager.monitor_windows(interval)
    
    elif command == "focus" and len(sys.argv) > 2:
        manager.focus_window(int(sys.argv[2]))
    
    elif command == "minimize" and len(sys.argv) > 2:
        manager.minimize_window(int(sys.argv[2]))
    
    elif command == "unminimize" and len(sys.argv) > 2:
        manager.unminimize_window(int(sys.argv[2]))
    
    elif command == "close" and len(sys.argv) > 2:
        manager.close_window(int(sys.argv[2]))
    
    elif command == "move" and len(sys.argv) > 4:
        manager.move_window(int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]))
    
    elif command == "resize" and len(sys.argv) > 4:
        manager.resize_window(int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]))
    
    else:
        print(f"Invalid command or missing arguments: {' '.join(sys.argv[1:])}")


if __name__ == "__main__":
    main()
#!/usr/bin/env python3
"""
Cursor Terminal Monitor and Auto-selector

Monitors Cursor terminal windows for Claude 4 and automatically selects option 2
when presented with 1,2,3 choices.
"""

import subprocess
import time
import sys
import re
from datetime import datetime


class CursorTerminalMonitor:
    def __init__(self):
        self.app_name = "Cursor"
        self.monitoring = True
        self.claude4_windows = set()
    
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
                print("Please enable assistive access for Terminal")
                sys.exit(1)
            return None
    
    def get_cursor_windows(self):
        """Get all Cursor windows."""
        windows = []
        
        # Check if Cursor is running
        script = 'tell application "System Events" to (name of processes) contains "Cursor"'
        if self.run_osascript(script) != "true":
            return windows
        
        # Get window count
        script = 'tell application "System Events" to tell process "Cursor" to count windows'
        count_result = self.run_osascript(script)
        if not count_result or not count_result.isdigit():
            return windows
        
        window_count = int(count_result)
        
        # Get info for each window
        for i in range(1, window_count + 1):
            # Get title
            script = f'tell application "System Events" to tell process "Cursor" to get name of window {i}'
            title = self.run_osascript(script) or "Unknown"
            windows.append({'index': i, 'title': title})
        
        return windows
    
    def get_window_ui_elements(self, window_index):
        """Get UI elements of a window to find terminal content."""
        # Try to get the entire UI element hierarchy
        script = f'''
        tell application "System Events"
            tell process "Cursor"
                tell window {window_index}
                    get entire contents
                end tell
            end tell
        end tell
        '''
        result = self.run_osascript(script)
        return result if result else ""
    
    def check_for_claude4(self, window_index):
        """Check if a window contains Claude 4 reference."""
        # Get window content
        content = self.get_window_ui_elements(window_index)
        
        # Check for Claude 4 patterns
        claude4_patterns = [
            "claude-4",
            "Claude 4",
            "claude 4",
            "CLAUDE-4",
            "Claude-4"
        ]
        
        for pattern in claude4_patterns:
            if pattern.lower() in content.lower():
                return True
        
        # Also check window title
        script = f'tell application "System Events" to tell process "Cursor" to get name of window {window_index}'
        title = self.run_osascript(script) or ""
        
        for pattern in claude4_patterns:
            if pattern.lower() in title.lower():
                return True
        
        return False
    
    def check_for_options_menu(self, window_index):
        """Check if window has a 1,2,3 options menu."""
        content = self.get_window_ui_elements(window_index)
        
        # Common patterns for option menus
        option_patterns = [
            r"1\s*[\.)\-]\s*.*\n.*2\s*[\.)\-]\s*.*\n.*3\s*[\.)\-]",  # 1. option\n2. option\n3. option
            r"Select.*:\s*\n.*1.*\n.*2.*\n.*3",  # Select: \n1\n2\n3
            r"\[1\].*\[2\].*\[3\]",  # [1] option [2] option [3] option
            r"Option 1.*Option 2.*Option 3",  # Option 1, Option 2, Option 3
        ]
        
        for pattern in option_patterns:
            if re.search(pattern, content, re.IGNORECASE | re.DOTALL):
                return True
        
        return False
    
    def select_option_2(self, window_index):
        """Automatically select option 2 in the window."""
        timestamp = datetime.now().strftime("%H:%M:%S")
        print(f"[{timestamp}] Selecting option 2 in window {window_index}")
        
        # First, make sure the window is focused
        script = f'''
        tell application "System Events"
            tell process "Cursor"
                set frontmost to true
                click window {window_index}
            end tell
        end tell
        '''
        self.run_osascript(script)
        
        # Small delay to ensure window is focused
        time.sleep(0.5)
        
        # Type "2" to select option 2
        script = '''
        tell application "System Events"
            keystroke "2"
        end tell
        '''
        self.run_osascript(script)
        
        # Optionally press Enter to confirm
        time.sleep(0.1)
        script = '''
        tell application "System Events"
            key code 36
        end tell
        '''
        self.run_osascript(script)
        
        print(f"[{timestamp}] ✓ Option 2 selected")
    
    def monitor_terminals(self, check_interval=2):
        """Monitor Cursor windows for Claude 4 and option menus."""
        print("Starting Cursor Terminal Monitor")
        print("Monitoring for Claude 4 and auto-selecting option 2...")
        print("Press Ctrl+C to stop\n")
        
        processed_menus = set()  # Track which windows we've already processed
        
        try:
            while self.monitoring:
                windows = self.get_cursor_windows()
                
                for window in windows:
                    index = window['index']
                    title = window['title']
                    
                    # Check for Claude 4
                    has_claude4 = self.check_for_claude4(index)
                    
                    if has_claude4 and index not in self.claude4_windows:
                        timestamp = datetime.now().strftime("%H:%M:%S")
                        print(f"[{timestamp}] ✓ Claude 4 detected in window {index}: {title}")
                        self.claude4_windows.add(index)
                    
                    # Check for options menu (only in Claude 4 windows)
                    if has_claude4 or index in self.claude4_windows:
                        window_key = f"{index}_{title}"
                        
                        if self.check_for_options_menu(index) and window_key not in processed_menus:
                            timestamp = datetime.now().strftime("%H:%M:%S")
                            print(f"[{timestamp}] 🎯 Options menu detected in window {index}")
                            self.select_option_2(index)
                            processed_menus.add(window_key)
                
                # Clean up processed menus if window titles change
                current_window_keys = {f"{w['index']}_{w['title']}" for w in windows}
                processed_menus = processed_menus.intersection(current_window_keys)
                
                time.sleep(check_interval)
                
        except KeyboardInterrupt:
            print("\n\nMonitoring stopped.")
    
    def run_diagnostic(self):
        """Run a diagnostic to show what the script can see."""
        print("Running diagnostic...")
        print("=" * 50)
        
        windows = self.get_cursor_windows()
        
        if not windows:
            print("No Cursor windows found.")
            return
        
        print(f"Found {len(windows)} Cursor window(s):\n")
        
        for window in windows:
            index = window['index']
            title = window['title']
            
            print(f"Window {index}: {title}")
            print(f"  Claude 4 detected: {self.check_for_claude4(index)}")
            print(f"  Options menu detected: {self.check_for_options_menu(index)}")
            
            # Try to get some content
            content = self.get_window_ui_elements(index)
            if content:
                preview = content[:200] + "..." if len(content) > 200 else content
                print(f"  Content preview: {preview}")
            print()


def main():
    monitor = CursorTerminalMonitor()
    
    if len(sys.argv) > 1 and sys.argv[1] == "diagnostic":
        monitor.run_diagnostic()
    else:
        monitor.monitor_terminals()


if __name__ == "__main__":
    main()
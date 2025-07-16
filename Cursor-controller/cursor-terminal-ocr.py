#!/usr/bin/env python3
"""
Cursor Terminal OCR Monitor

Uses screenshot and OCR to detect Claude 4 and auto-select option 2.
This is more reliable than UI element inspection for terminal content.
"""

import subprocess
import time
import sys
import os
import re
from datetime import datetime
import tempfile


class CursorTerminalOCR:
    def __init__(self):
        self.app_name = "Cursor"
        self.monitoring = True
        self.claude4_windows = set()
        self.processed_selections = set()
    
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
                sys.exit(1)
            return None
    
    def get_cursor_windows(self):
        """Get all Cursor windows with their bounds."""
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
            window_info = {'index': i}
            
            # Get title
            script = f'tell application "System Events" to tell process "Cursor" to get name of window {i}'
            window_info['title'] = self.run_osascript(script) or "Unknown"
            
            # Get position
            script = f'tell application "System Events" to tell process "Cursor" to get position of window {i}'
            pos = self.run_osascript(script)
            if pos:
                window_info['x'], window_info['y'] = map(int, pos.split(", "))
            
            # Get size
            script = f'tell application "System Events" to tell process "Cursor" to get size of window {i}'
            size = self.run_osascript(script)
            if size:
                window_info['width'], window_info['height'] = map(int, size.split(", "))
            
            # Check if minimized
            script = f'tell application "System Events" to tell process "Cursor" to get value of attribute "AXMinimized" of window {i}'
            window_info['minimized'] = self.run_osascript(script) == "true"
            
            if not window_info.get('minimized', True):
                windows.append(window_info)
        
        return windows
    
    def capture_window_screenshot(self, window_info):
        """Capture a screenshot of a specific window area."""
        # Create temporary file for screenshot
        temp_file = tempfile.NamedTemporaryFile(suffix='.png', delete=False)
        temp_path = temp_file.name
        temp_file.close()
        
        # Calculate screenshot bounds
        x = window_info.get('x', 0)
        y = window_info.get('y', 0)
        width = window_info.get('width', 800)
        height = window_info.get('height', 600)
        
        # Use screencapture with bounds
        cmd = ['screencapture', '-x', '-R', f'{x},{y},{width},{height}', temp_path]
        subprocess.run(cmd, check=True)
        
        return temp_path
    
    def ocr_screenshot(self, image_path):
        """Perform OCR on screenshot using macOS Vision framework."""
        script = f'''
        use framework "Vision"
        use framework "Foundation"
        use framework "AppKit"
        
        on run
            set imagePath to "{image_path}"
            set theImage to current application's NSImage's alloc()'s initWithContentsOfFile:imagePath
            
            if theImage is missing value then
                return "Error: Could not load image"
            end if
            
            set imageRep to theImage's representations()'s objectAtIndex:0
            set theCGImage to imageRep's CGImage()
            
            set request to current application's VNRecognizeTextRequest's alloc()'s init()
            request's setRecognitionLevel:(current application's VNRequestTextRecognitionLevelAccurate)
            
            set requestHandler to current application's VNImageRequestHandler's alloc()'s initWithCGImage:theCGImage options:(current application's NSDictionary's dictionary())
            
            requestHandler's performRequests:{request} |error|:(missing value)
            
            set results to request's results()
            set textResults to ""
            
            repeat with observation in results
                set candidate to (observation's topCandidates:1)'s objectAtIndex:0
                set textResults to textResults & (candidate's |string|() as string) & linefeed
            end repeat
            
            return textResults
        end run
        '''
        
        # Save script to temporary file
        script_file = tempfile.NamedTemporaryFile(suffix='.scpt', delete=False, mode='w')
        script_file.write(script)
        script_file.close()
        
        # Run the script
        result = subprocess.run(
            ['osascript', script_file.name],
            capture_output=True,
            text=True
        )
        
        # Clean up
        os.unlink(script_file.name)
        
        return result.stdout if result.returncode == 0 else ""
    
    def check_for_claude4(self, text):
        """Check if text contains Claude 4 reference."""
        claude4_patterns = [
            r"claude[\s\-]?4",
            r"Claude[\s\-]?4",
            r"CLAUDE[\s\-]?4",
            r"opus[\s\-]?4",
            r"Opus[\s\-]?4"
        ]
        
        for pattern in claude4_patterns:
            if re.search(pattern, text, re.IGNORECASE):
                return True
        return False
    
    def check_for_options_menu(self, text):
        """Check if text contains a 1,2,3 options menu."""
        # Look for numbered options
        lines = text.split('\n')
        
        # Check if we have lines with 1, 2, and 3
        has_1 = any('1' in line for line in lines)
        has_2 = any('2' in line for line in lines)
        has_3 = any('3' in line for line in lines)
        
        if has_1 and has_2 and has_3:
            # Additional patterns to confirm it's a menu
            menu_patterns = [
                r"select",
                r"choose",
                r"option",
                r"choice",
                r"pick",
                r"which.*model",
                r"available.*models"
            ]
            
            text_lower = text.lower()
            for pattern in menu_patterns:
                if re.search(pattern, text_lower):
                    return True
            
            # Check for sequential 1, 2, 3
            if re.search(r"1.*2.*3", text, re.DOTALL):
                return True
        
        return False
    
    def focus_and_select_option_2(self, window_index):
        """Focus window and select option 2."""
        timestamp = datetime.now().strftime("%H:%M:%S")
        print(f"[{timestamp}] Auto-selecting option 2 in window {window_index}")
        
        # Focus the window
        script = f'''
        tell application "System Events"
            tell process "Cursor"
                set frontmost to true
                click window {window_index}
            end tell
        end tell
        '''
        self.run_osascript(script)
        time.sleep(0.5)
        
        # Type "2"
        script = '''
        tell application "System Events"
            keystroke "2"
        end tell
        '''
        self.run_osascript(script)
        time.sleep(0.1)
        
        # Press Enter
        script = '''
        tell application "System Events"
            key code 36
        end tell
        '''
        self.run_osascript(script)
        
        print(f"[{timestamp}] ✓ Option 2 selected and confirmed")
    
    def monitor_with_ocr(self, check_interval=3):
        """Monitor Cursor windows using OCR."""
        print("Starting Cursor Terminal OCR Monitor")
        print("Monitoring for Claude 4 and auto-selecting option 2...")
        print("Press Ctrl+C to stop\n")
        
        try:
            while self.monitoring:
                windows = self.get_cursor_windows()
                
                for window in windows:
                    index = window['index']
                    title = window['title']
                    
                    # Skip if window is too small
                    if window.get('width', 0) < 200 or window.get('height', 0) < 100:
                        continue
                    
                    try:
                        # Capture screenshot
                        screenshot_path = self.capture_window_screenshot(window)
                        
                        # Perform OCR
                        text = self.ocr_screenshot(screenshot_path)
                        
                        # Clean up screenshot
                        os.unlink(screenshot_path)
                        
                        # Check for Claude 4
                        if self.check_for_claude4(text):
                            if index not in self.claude4_windows:
                                timestamp = datetime.now().strftime("%H:%M:%S")
                                print(f"[{timestamp}] ✓ Claude 4 detected in window {index}: {title}")
                                self.claude4_windows.add(index)
                            
                            # Check for options menu
                            window_key = f"{index}_{title}_{len(text)}"
                            if self.check_for_options_menu(text) and window_key not in self.processed_selections:
                                timestamp = datetime.now().strftime("%H:%M:%S")
                                print(f"[{timestamp}] 🎯 Options menu detected!")
                                self.focus_and_select_option_2(index)
                                self.processed_selections.add(window_key)
                    
                    except Exception as e:
                        # Silently continue on errors
                        pass
                
                time.sleep(check_interval)
                
        except KeyboardInterrupt:
            print("\n\nMonitoring stopped.")
    
    def run_diagnostic(self):
        """Run diagnostic to test OCR functionality."""
        print("Running OCR diagnostic...")
        print("=" * 50)
        
        windows = self.get_cursor_windows()
        
        if not windows:
            print("No Cursor windows found.")
            return
        
        print(f"Found {len(windows)} Cursor window(s):\n")
        
        for window in windows[:2]:  # Test first 2 windows
            index = window['index']
            title = window['title']
            
            print(f"Window {index}: {title}")
            print(f"  Position: ({window.get('x')}, {window.get('y')})")
            print(f"  Size: {window.get('width')}x{window.get('height')}")
            
            try:
                # Capture and OCR
                screenshot_path = self.capture_window_screenshot(window)
                text = self.ocr_screenshot(screenshot_path)
                os.unlink(screenshot_path)
                
                if text:
                    print(f"  Claude 4 detected: {self.check_for_claude4(text)}")
                    print(f"  Options menu detected: {self.check_for_options_menu(text)}")
                    print(f"  OCR text preview:")
                    preview = text[:300] + "..." if len(text) > 300 else text
                    for line in preview.split('\n')[:5]:
                        print(f"    {line}")
                else:
                    print("  No text detected")
            except Exception as e:
                print(f"  Error: {e}")
            
            print()


def main():
    monitor = CursorTerminalOCR()
    
    if len(sys.argv) > 1:
        if sys.argv[1] == "diagnostic":
            monitor.run_diagnostic()
        elif sys.argv[1] == "test":
            # Test mode - single pass
            monitor.check_interval = 1
            monitor.monitoring = False
            monitor.monitor_with_ocr(1)
    else:
        monitor.monitor_with_ocr()


if __name__ == "__main__":
    main()
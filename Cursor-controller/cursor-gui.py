#!/usr/bin/env python3
"""
Cursor Window Controller GUI

A graphical interface for monitoring and controlling Cursor windows.
Uses tkinter for the GUI.
"""

import tkinter as tk
from tkinter import ttk, messagebox
import subprocess
import threading
import time
from datetime import datetime


class CursorWindowGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Cursor Window Controller")
        self.root.geometry("800x600")
        
        # Variables
        self.monitoring = False
        self.windows_data = []
        
        # Create GUI elements
        self.create_widgets()
        
        # Initial window list
        self.refresh_windows()
    
    def create_widgets(self):
        # Title
        title_label = tk.Label(self.root, text="Cursor Window Controller", 
                              font=("Arial", 18, "bold"))
        title_label.pack(pady=10)
        
        # Control buttons frame
        control_frame = tk.Frame(self.root)
        control_frame.pack(pady=10)
        
        tk.Button(control_frame, text="Refresh", command=self.refresh_windows,
                 bg="#4CAF50", fg="white", padx=20).pack(side=tk.LEFT, padx=5)
        
        self.monitor_button = tk.Button(control_frame, text="Start Monitor", 
                                       command=self.toggle_monitor,
                                       bg="#2196F3", fg="white", padx=20)
        self.monitor_button.pack(side=tk.LEFT, padx=5)
        
        # Window list frame
        list_frame = tk.Frame(self.root)
        list_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=10)
        
        # Scrollbar
        scrollbar = tk.Scrollbar(list_frame)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        
        # Window listbox
        self.window_listbox = tk.Listbox(list_frame, yscrollcommand=scrollbar.set,
                                        font=("Arial", 12), height=10)
        self.window_listbox.pack(fill=tk.BOTH, expand=True)
        scrollbar.config(command=self.window_listbox.yview)
        
        # Window details
        details_frame = tk.LabelFrame(self.root, text="Window Details", padx=10, pady=10)
        details_frame.pack(fill=tk.X, padx=20, pady=10)
        
        self.details_label = tk.Label(details_frame, text="Select a window to see details",
                                     justify=tk.LEFT, font=("Arial", 11))
        self.details_label.pack()
        
        # Action buttons frame
        action_frame = tk.LabelFrame(self.root, text="Window Actions", padx=10, pady=10)
        action_frame.pack(fill=tk.X, padx=20, pady=10)
        
        # First row of actions
        row1 = tk.Frame(action_frame)
        row1.pack(pady=5)
        
        tk.Button(row1, text="Focus", command=self.focus_window,
                 bg="#FF9800", fg="white", width=12).pack(side=tk.LEFT, padx=5)
        tk.Button(row1, text="Minimize", command=self.minimize_window,
                 bg="#9C27B0", fg="white", width=12).pack(side=tk.LEFT, padx=5)
        tk.Button(row1, text="Unminimize", command=self.unminimize_window,
                 bg="#3F51B5", fg="white", width=12).pack(side=tk.LEFT, padx=5)
        tk.Button(row1, text="Close", command=self.close_window,
                 bg="#F44336", fg="white", width=12).pack(side=tk.LEFT, padx=5)
        
        # Position/Size controls
        pos_frame = tk.Frame(action_frame)
        pos_frame.pack(pady=10)
        
        tk.Label(pos_frame, text="Move to:").pack(side=tk.LEFT, padx=5)
        tk.Label(pos_frame, text="X:").pack(side=tk.LEFT)
        self.x_entry = tk.Entry(pos_frame, width=8)
        self.x_entry.pack(side=tk.LEFT, padx=2)
        
        tk.Label(pos_frame, text="Y:").pack(side=tk.LEFT, padx=(10, 0))
        self.y_entry = tk.Entry(pos_frame, width=8)
        self.y_entry.pack(side=tk.LEFT, padx=2)
        
        tk.Button(pos_frame, text="Move", command=self.move_window,
                 bg="#00BCD4", fg="white").pack(side=tk.LEFT, padx=10)
        
        size_frame = tk.Frame(action_frame)
        size_frame.pack(pady=5)
        
        tk.Label(size_frame, text="Resize to:").pack(side=tk.LEFT, padx=5)
        tk.Label(size_frame, text="W:").pack(side=tk.LEFT)
        self.w_entry = tk.Entry(size_frame, width=8)
        self.w_entry.pack(side=tk.LEFT, padx=2)
        
        tk.Label(size_frame, text="H:").pack(side=tk.LEFT, padx=(10, 0))
        self.h_entry = tk.Entry(size_frame, width=8)
        self.h_entry.pack(side=tk.LEFT, padx=2)
        
        tk.Button(size_frame, text="Resize", command=self.resize_window,
                 bg="#009688", fg="white").pack(side=tk.LEFT, padx=10)
        
        # Status bar
        self.status_label = tk.Label(self.root, text="Ready", 
                                    bd=1, relief=tk.SUNKEN, anchor=tk.W)
        self.status_label.pack(side=tk.BOTTOM, fill=tk.X)
        
        # Bind selection event
        self.window_listbox.bind('<<ListboxSelect>>', self.on_select)
    
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
                messagebox.showerror("Permission Error", 
                    "Assistive access required!\n\n"
                    "Please enable assistive access for Terminal:\n"
                    "1. Open System Preferences > Security & Privacy > Privacy\n"
                    "2. Select 'Accessibility' from the left panel\n"
                    "3. Add Terminal to the list and check the box")
            return None
    
    def get_windows(self):
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
            window_info = {'index': i}
            
            # Get title
            script = f'tell application "System Events" to tell process "Cursor" to get name of window {i}'
            window_info['title'] = self.run_osascript(script) or "Unknown"
            
            # Get position
            script = f'tell application "System Events" to tell process "Cursor" to get position of window {i}'
            pos = self.run_osascript(script)
            if pos:
                window_info['position'] = [int(x) for x in pos.split(", ")]
            
            # Get size
            script = f'tell application "System Events" to tell process "Cursor" to get size of window {i}'
            size = self.run_osascript(script)
            if size:
                window_info['size'] = [int(x) for x in size.split(", ")]
            
            # Check if minimized
            script = f'tell application "System Events" to tell process "Cursor" to get value of attribute "AXMinimized" of window {i}'
            window_info['minimized'] = self.run_osascript(script) == "true"
            
            windows.append(window_info)
        
        return windows
    
    def refresh_windows(self):
        """Refresh the window list."""
        self.windows_data = self.get_windows()
        
        # Clear listbox
        self.window_listbox.delete(0, tk.END)
        
        # Add windows to listbox
        for window in self.windows_data:
            status = "📕" if window.get('minimized') else "📗"
            text = f"{status} Window {window['index']}: {window['title']}"
            self.window_listbox.insert(tk.END, text)
        
        self.status_label.config(text=f"Found {len(self.windows_data)} windows")
    
    def on_select(self, event):
        """Handle window selection."""
        selection = self.window_listbox.curselection()
        if not selection:
            return
        
        index = selection[0]
        if index < len(self.windows_data):
            window = self.windows_data[index]
            
            details = f"Title: {window['title']}\\n"
            details += f"Index: {window['index']}\\n"
            details += f"Position: {window.get('position', 'Unknown')}\\n"
            details += f"Size: {window.get('size', 'Unknown')}\\n"
            details += f"Minimized: {'Yes' if window.get('minimized') else 'No'}"
            
            self.details_label.config(text=details)
            
            # Pre-fill position and size entries
            if 'position' in window:
                self.x_entry.delete(0, tk.END)
                self.x_entry.insert(0, str(window['position'][0]))
                self.y_entry.delete(0, tk.END)
                self.y_entry.insert(0, str(window['position'][1]))
            
            if 'size' in window:
                self.w_entry.delete(0, tk.END)
                self.w_entry.insert(0, str(window['size'][0]))
                self.h_entry.delete(0, tk.END)
                self.h_entry.insert(0, str(window['size'][1]))
    
    def get_selected_window_index(self):
        """Get the index of the selected window."""
        selection = self.window_listbox.curselection()
        if not selection:
            messagebox.showwarning("No Selection", "Please select a window first")
            return None
        
        list_index = selection[0]
        if list_index < len(self.windows_data):
            return self.windows_data[list_index]['index']
        return None
    
    def focus_window(self):
        """Focus the selected window."""
        index = self.get_selected_window_index()
        if index:
            script = f'''
            tell application "System Events"
                tell process "Cursor"
                    set frontmost to true
                    click window {index}
                end tell
            end tell
            '''
            self.run_osascript(script)
            self.status_label.config(text=f"Focused window {index}")
    
    def minimize_window(self):
        """Minimize the selected window."""
        index = self.get_selected_window_index()
        if index:
            script = f'''
            tell application "System Events"
                tell process "Cursor"
                    set value of attribute "AXMinimized" of window {index} to true
                end tell
            end tell
            '''
            self.run_osascript(script)
            self.status_label.config(text=f"Minimized window {index}")
            self.refresh_windows()
    
    def unminimize_window(self):
        """Unminimize the selected window."""
        index = self.get_selected_window_index()
        if index:
            script = f'''
            tell application "System Events"
                tell process "Cursor"
                    set value of attribute "AXMinimized" of window {index} to false
                end tell
            end tell
            '''
            self.run_osascript(script)
            self.status_label.config(text=f"Unminimized window {index}")
            self.refresh_windows()
    
    def close_window(self):
        """Close the selected window."""
        index = self.get_selected_window_index()
        if index:
            if messagebox.askyesno("Confirm", f"Close window {index}?"):
                script = f'''
                tell application "System Events"
                    tell process "Cursor"
                        click button 1 of window {index}
                    end tell
                end tell
                '''
                self.run_osascript(script)
                self.status_label.config(text=f"Closed window {index}")
                time.sleep(0.5)
                self.refresh_windows()
    
    def move_window(self):
        """Move the selected window."""
        index = self.get_selected_window_index()
        if index:
            try:
                x = int(self.x_entry.get())
                y = int(self.y_entry.get())
                
                script = f'''
                tell application "System Events"
                    tell process "Cursor"
                        set position of window {index} to {{{x}, {y}}}
                    end tell
                end tell
                '''
                self.run_osascript(script)
                self.status_label.config(text=f"Moved window {index} to ({x}, {y})")
                self.refresh_windows()
            except ValueError:
                messagebox.showerror("Invalid Input", "Please enter valid numbers for X and Y")
    
    def resize_window(self):
        """Resize the selected window."""
        index = self.get_selected_window_index()
        if index:
            try:
                w = int(self.w_entry.get())
                h = int(self.h_entry.get())
                
                script = f'''
                tell application "System Events"
                    tell process "Cursor"
                        set size of window {index} to {{{w}, {h}}}
                    end tell
                end tell
                '''
                self.run_osascript(script)
                self.status_label.config(text=f"Resized window {index} to {w}x{h}")
                self.refresh_windows()
            except ValueError:
                messagebox.showerror("Invalid Input", "Please enter valid numbers for width and height")
    
    def toggle_monitor(self):
        """Toggle window monitoring."""
        if not self.monitoring:
            self.monitoring = True
            self.monitor_button.config(text="Stop Monitor", bg="#F44336")
            self.monitor_thread = threading.Thread(target=self.monitor_windows, daemon=True)
            self.monitor_thread.start()
        else:
            self.monitoring = False
            self.monitor_button.config(text="Start Monitor", bg="#2196F3")
    
    def monitor_windows(self):
        """Monitor windows in background."""
        previous_state = []
        
        while self.monitoring:
            current_windows = self.get_windows()
            
            if current_windows != previous_state:
                # Update GUI in main thread
                self.root.after(0, self.refresh_windows)
                previous_state = current_windows.copy()
            
            time.sleep(1)


def main():
    root = tk.Tk()
    app = CursorWindowGUI(root)
    root.mainloop()


if __name__ == "__main__":
    main()
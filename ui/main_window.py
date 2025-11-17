"""
MainWindow - Primary UI window for SimpleCP.

This implements the header-based two-column layout as described in
UI_UX_SPECIFICATION_v3.md with focus on the snippet workflow.
"""

import tkinter as tk
from tkinter import ttk, messagebox
import pyperclip


class MainWindow(tk.Tk):
    """
    Main application window with header-based two-column layout.

    Layout structure:
    - Header bar (title + icons)
    - Search bar (always visible)
    - Control bar (Save as Snippet, Manage Folders, etc.)
    - Two-column content area (Recent Clips | Saved Snippets)
    """

    def __init__(self, clipboard_manager):
        super().__init__()

        # Reference to the clipboard manager
        self.clipboard_manager = clipboard_manager

        # Window configuration
        self.title("SimpleCP")
        self.geometry("800x600")
        self.configure(bg='#F7FAFC')

        # Create UI components
        self.create_header_bar()
        self.create_search_bar()
        self.create_control_bar()
        self.create_two_column_layout()

        # Bind window close to hide instead
        self.protocol("WM_DELETE_WINDOW", self.hide_window)

    def create_header_bar(self):
        """Create the header bar with title and icons."""
        header_frame = tk.Frame(self, bg='#2D3748', height=40)
        header_frame.pack(fill=tk.X, side=tk.TOP)
        header_frame.pack_propagate(False)

        # Title
        title_label = tk.Label(
            header_frame,
            text="SimpleCP",
            bg='#2D3748',
            fg='white',
            font=('SF Pro', 14, 'bold')
        )
        title_label.pack(side=tk.LEFT, padx=15, pady=8)

        # Settings button (right side)
        settings_btn = tk.Button(
            header_frame,
            text="⚙️",
            bg='#2D3748',
            fg='white',
            relief=tk.FLAT,
            font=('SF Pro', 16),
            cursor='hand2',
            command=self.show_settings
        )
        settings_btn.pack(side=tk.RIGHT, padx=10, pady=8)

        # Search icon (right side)
        search_icon = tk.Label(
            header_frame,
            text="🔍",
            bg='#2D3748',
            fg='white',
            font=('SF Pro', 16)
        )
        search_icon.pack(side=tk.RIGHT, padx=5, pady=8)

    def create_search_bar(self):
        """Create the always-visible search bar."""
        search_frame = tk.Frame(self, bg='#EDF2F7', height=45)
        search_frame.pack(fill=tk.X, side=tk.TOP)
        search_frame.pack_propagate(False)

        # Search entry
        self.search_var = tk.StringVar()
        self.search_var.trace('w', self.on_search_change)

        search_entry = tk.Entry(
            search_frame,
            textvariable=self.search_var,
            font=('SF Pro', 13),
            bg='white',
            relief=tk.FLAT,
            bd=1
        )
        search_entry.insert(0, "🔍 Search clips and snippets...")
        search_entry.pack(fill=tk.X, padx=15, pady=8)

        # Bind focus events for placeholder text
        search_entry.bind('<FocusIn>', lambda e: self.clear_placeholder(search_entry))
        search_entry.bind('<FocusOut>', lambda e: self.restore_placeholder(search_entry))

    def create_control_bar(self):
        """Create the control bar with snippet management buttons."""
        control_frame = tk.Frame(self, bg='#E2E8F0', height=45)
        control_frame.pack(fill=tk.X, side=tk.TOP)
        control_frame.pack_propagate(False)

        # Save as Snippet button (PRIMARY ACTION)
        save_btn = tk.Button(
            control_frame,
            text="💾 Save as Snippet",
            bg='#3182CE',
            fg='white',
            font=('SF Pro', 12, 'bold'),
            relief=tk.FLAT,
            cursor='hand2',
            padx=15,
            pady=5,
            command=self.open_save_snippet_dialog
        )
        save_btn.pack(side=tk.LEFT, padx=10, pady=8)

        # Manage Folders button
        manage_btn = tk.Button(
            control_frame,
            text="📁 Manage Folders",
            bg='#E2E8F0',
            fg='#2D3748',
            font=('SF Pro', 11),
            relief=tk.FLAT,
            cursor='hand2',
            padx=12,
            command=self.manage_folders
        )
        manage_btn.pack(side=tk.LEFT, padx=5, pady=8)

        # Clear History button
        clear_btn = tk.Button(
            control_frame,
            text="📋 Clear History",
            bg='#E2E8F0',
            fg='#2D3748',
            font=('SF Pro', 11),
            relief=tk.FLAT,
            cursor='hand2',
            padx=12,
            command=self.clear_history
        )
        clear_btn.pack(side=tk.LEFT, padx=5, pady=8)

        # Right side buttons
        import_btn = tk.Button(
            control_frame,
            text="📥 Import",
            bg='#E2E8F0',
            fg='#2D3748',
            font=('SF Pro', 11),
            relief=tk.FLAT,
            cursor='hand2',
            padx=12,
            command=self.import_snippets
        )
        import_btn.pack(side=tk.RIGHT, padx=5, pady=8)

        export_btn = tk.Button(
            control_frame,
            text="📤 Export",
            bg='#E2E8F0',
            fg='#2D3748',
            font=('SF Pro', 11),
            relief=tk.FLAT,
            cursor='hand2',
            padx=12,
            command=self.export_snippets
        )
        export_btn.pack(side=tk.RIGHT, padx=10, pady=8)

    def create_two_column_layout(self):
        """Create the two-column content area."""
        # Container for both columns
        content_frame = tk.Frame(self, bg='#F7FAFC')
        content_frame.pack(fill=tk.BOTH, expand=True, side=tk.TOP)

        # LEFT COLUMN: Recent Clips
        left_frame = tk.Frame(content_frame, bg='white', relief=tk.FLAT, bd=1)
        left_frame.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=(10, 5), pady=10)

        # Left column header
        left_header = tk.Label(
            left_frame,
            text="📋 RECENT CLIPS",
            bg='#EDF2F7',
            fg='#2D3748',
            font=('SF Pro', 12, 'bold'),
            anchor='w',
            padx=10,
            pady=8
        )
        left_header.pack(fill=tk.X, side=tk.TOP)

        # Left column content (scrollable)
        self.left_scrollbar = tk.Scrollbar(left_frame)
        self.left_scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        self.recent_clips_list = tk.Listbox(
            left_frame,
            font=('SF Mono', 11),
            bg='white',
            fg='#2D3748',
            relief=tk.FLAT,
            yscrollcommand=self.left_scrollbar.set,
            selectmode=tk.SINGLE
        )
        self.recent_clips_list.pack(fill=tk.BOTH, expand=True, side=tk.LEFT)
        self.left_scrollbar.config(command=self.recent_clips_list.yview)

        # Bind double-click to copy
        self.recent_clips_list.bind('<Double-Button-1>', self.copy_clip)

        # RIGHT COLUMN: Saved Snippets
        right_frame = tk.Frame(content_frame, bg='white', relief=tk.FLAT, bd=1)
        right_frame.pack(side=tk.RIGHT, fill=tk.BOTH, expand=True, padx=(5, 10), pady=10)

        # Right column header
        right_header = tk.Label(
            right_frame,
            text="📁 SAVED SNIPPETS",
            bg='#EDF2F7',
            fg='#2D3748',
            font=('SF Pro', 12, 'bold'),
            anchor='w',
            padx=10,
            pady=8
        )
        right_header.pack(fill=tk.X, side=tk.TOP)

        # Right column content (tree view for folders)
        self.right_scrollbar = tk.Scrollbar(right_frame)
        self.right_scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        self.snippets_tree = ttk.Treeview(
            right_frame,
            yscrollcommand=self.right_scrollbar.set,
            selectmode='browse'
        )
        self.snippets_tree.pack(fill=tk.BOTH, expand=True, side=tk.LEFT)
        self.right_scrollbar.config(command=self.snippets_tree.yview)

        # Bind double-click to copy snippet
        self.snippets_tree.bind('<Double-Button-1>', self.copy_snippet)

        # Load initial data
        self.refresh_recent_clips()
        self.refresh_snippets()

    def refresh_recent_clips(self):
        """Refresh the recent clips list from clipboard manager."""
        self.recent_clips_list.delete(0, tk.END)

        # Get history from clipboard manager
        history = self.clipboard_manager.clipboard_history[:10]  # Show top 10

        for i, item in enumerate(history):
            preview = item.get('preview', item.get('content', '')[:50])
            self.recent_clips_list.insert(tk.END, f"{i+1}. {preview}")

    def refresh_snippets(self):
        """Refresh the snippets tree from clipboard manager."""
        # Clear existing
        for item in self.snippets_tree.get_children():
            self.snippets_tree.delete(item)

        # Get snippets from clipboard manager
        folders = self.clipboard_manager.snippet_folders

        if not folders:
            # Show placeholder
            self.snippets_tree.insert('', 'end', text='No snippets yet. Click "💾 Save as Snippet" to create one!')
        else:
            # Populate tree with folders and snippets
            for folder_name, folder_data in folders.items():
                folder_node = self.snippets_tree.insert('', 'end', text=f"📁 {folder_name}")

                # Add snippets in this folder
                snippets = folder_data.get('snippets', [])
                for snippet in snippets:
                    snippet_name = snippet.get('name', 'Untitled')
                    self.snippets_tree.insert(folder_node, 'end', text=f"  {snippet_name}")

    # ===== EVENT HANDLERS =====

    def open_save_snippet_dialog(self):
        """Open the complete 'Save as Snippet' workflow dialog."""
        # Import here to avoid circular import
        from ui.snippet_workflow import SnippetSaveDialog

        # Get current clipboard content
        current_content = pyperclip.paste()

        if not current_content.strip():
            tk.messagebox.showwarning(
                "No Clipboard Content",
                "Your clipboard is empty. Copy some text first, then save it as a snippet."
            )
            return

        # Open the save dialog
        dialog = SnippetSaveDialog(self, current_content, self.clipboard_manager)
        self.wait_window(dialog)

        # Refresh snippets after dialog closes
        self.refresh_snippets()

    def manage_folders(self):
        """Open folder management dialog."""
        tk.messagebox.showinfo("Manage Folders", "Folder management coming soon!")

    def clear_history(self):
        """Clear all clipboard history."""
        if tk.messagebox.askyesno("Clear History", "Are you sure you want to clear all clipboard history?"):
            self.clipboard_manager.clear_history(None)
            self.refresh_recent_clips()

    def import_snippets(self):
        """Import snippets from file."""
        tk.messagebox.showinfo("Import", "Import functionality coming soon!")

    def export_snippets(self):
        """Export snippets to file."""
        tk.messagebox.showinfo("Export", "Export functionality coming soon!")

    def show_settings(self):
        """Show settings window."""
        tk.messagebox.showinfo("Settings", "Settings window coming soon!")

    def on_search_change(self, *args):
        """Handle search text changes."""
        search_term = self.search_var.get().lower()
        if search_term.startswith("🔍"):
            return  # Ignore placeholder

        # TODO: Implement search filtering
        print(f"Searching for: {search_term}")

    def copy_clip(self, event):
        """Copy selected clip to clipboard."""
        selection = self.recent_clips_list.curselection()
        if selection:
            idx = selection[0]
            item = self.clipboard_manager.clipboard_history[idx]
            pyperclip.copy(item['content'])
            print(f"📋 Copied: {item['preview']}")

    def copy_snippet(self, event):
        """Copy selected snippet to clipboard."""
        selection = self.snippets_tree.selection()
        if selection:
            item = self.snippets_tree.item(selection[0])
            # TODO: Implement snippet copying
            print(f"📋 Copying snippet: {item['text']}")

    def clear_placeholder(self, entry):
        """Clear placeholder text on focus."""
        if entry.get().startswith("🔍"):
            entry.delete(0, tk.END)

    def restore_placeholder(self, entry):
        """Restore placeholder text on focus out."""
        if not entry.get():
            entry.insert(0, "🔍 Search clips and snippets...")

    def show_window(self):
        """Show the main window."""
        self.deiconify()
        self.lift()
        self.focus_force()

    def hide_window(self):
        """Hide the window instead of closing."""
        self.withdraw()


if __name__ == "__main__":
    # Test window independently
    root = MainWindow(None)
    root.mainloop()

"""
Snippet Workflow - Complete "Save as Snippet" dialog implementation.

This is the KEY DIFFERENTIATOR for SimpleCP - an efficient, streamlined
workflow for saving clipboard content as organized snippets.

Implements the complete workflow from UI_UX_SPECIFICATION_v3.md:
- Content preview
- Smart name suggestions
- Folder selection with option to create new
- Optional tags
- All in one dialog
"""

import tkinter as tk
from tkinter import ttk, messagebox
from datetime import datetime

# Import the name suggester utility
from utils.name_suggester import NameSuggester


# NameSuggester is imported from utils.name_suggester
# This provides smart name suggestions for snippets based on content analysis


class SnippetSaveDialog(tk.Toplevel):
    """
    Complete 'Save as Snippet' workflow dialog.

    This dialog provides the complete workflow for saving clipboard
    content as a snippet with:
    - Content preview
    - Smart name suggestion
    - Folder selection
    - Option to create new folder
    - Optional tags
    """

    def __init__(self, parent, content, clipboard_manager):
        super().__init__(parent)

        self.content = content
        self.clipboard_manager = clipboard_manager
        self.name_suggester = NameSuggester()

        # Dialog configuration
        self.title("Save as Snippet")
        self.geometry("600x500")
        self.configure(bg='#F7FAFC')
        self.resizable(False, False)

        # Make modal
        self.transient(parent)
        self.grab_set()

        # Create the dialog UI
        self.create_dialog()

        # Center on parent
        self.center_on_parent(parent)

    def create_dialog(self):
        """Create the complete dialog UI."""
        # Header
        header = tk.Label(
            self,
            text="💾 Save as Snippet",
            bg='#2D3748',
            fg='white',
            font=('SF Pro', 14, 'bold'),
            pady=12
        )
        header.pack(fill=tk.X)

        # Main content area
        content_frame = tk.Frame(self, bg='#F7FAFC', padx=20, pady=20)
        content_frame.pack(fill=tk.BOTH, expand=True)

        # 1. CONTENT PREVIEW
        preview_label = tk.Label(
            content_frame,
            text="Content Preview:",
            bg='#F7FAFC',
            fg='#2D3748',
            font=('SF Pro', 11, 'bold'),
            anchor='w'
        )
        preview_label.pack(fill=tk.X, pady=(0, 5))

        # Preview text box (read-only)
        preview_frame = tk.Frame(content_frame, bg='white', relief=tk.SOLID, bd=1)
        preview_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 15))

        preview_scrollbar = tk.Scrollbar(preview_frame)
        preview_scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        self.preview_text = tk.Text(
            preview_frame,
            height=8,
            font=('SF Mono', 10),
            bg='#F8F9FA',
            fg='#2D3748',
            relief=tk.FLAT,
            wrap=tk.WORD,
            yscrollcommand=preview_scrollbar.set,
            state=tk.DISABLED
        )
        self.preview_text.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        preview_scrollbar.config(command=self.preview_text.yview)

        # Insert content into preview
        self.preview_text.config(state=tk.NORMAL)
        self.preview_text.insert('1.0', self.content)
        self.preview_text.config(state=tk.DISABLED)

        # 2. SNIPPET NAME
        name_label = tk.Label(
            content_frame,
            text="Snippet Name:",
            bg='#F7FAFC',
            fg='#2D3748',
            font=('SF Pro', 11, 'bold'),
            anchor='w'
        )
        name_label.pack(fill=tk.X, pady=(0, 5))

        self.name_var = tk.StringVar()
        suggested_name = self.name_suggester.suggest(self.content)
        self.name_var.set(suggested_name)

        name_entry = tk.Entry(
            content_frame,
            textvariable=self.name_var,
            font=('SF Pro', 12),
            bg='white',
            relief=tk.SOLID,
            bd=1
        )
        name_entry.pack(fill=tk.X, pady=(0, 15), ipady=5)
        name_entry.select_range(0, tk.END)  # Select all for easy editing
        name_entry.focus()

        # 3. SAVE TO FOLDER
        folder_label = tk.Label(
            content_frame,
            text="Save to Folder:",
            bg='#F7FAFC',
            fg='#2D3748',
            font=('SF Pro', 11, 'bold'),
            anchor='w'
        )
        folder_label.pack(fill=tk.X, pady=(0, 5))

        # Folder dropdown
        existing_folders = list(self.clipboard_manager.snippet_folders.keys())
        if not existing_folders:
            existing_folders = ["My Snippets"]  # Default folder

        self.folder_var = tk.StringVar()
        self.folder_var.set(existing_folders[0])

        folder_dropdown = ttk.Combobox(
            content_frame,
            textvariable=self.folder_var,
            values=existing_folders,
            font=('SF Pro', 11),
            state='readonly'
        )
        folder_dropdown.pack(fill=tk.X, pady=(0, 10), ipady=3)

        # Option to create new folder
        self.create_new_folder_var = tk.BooleanVar(value=False)
        create_folder_check = tk.Checkbutton(
            content_frame,
            text="Create new folder:",
            variable=self.create_new_folder_var,
            bg='#F7FAFC',
            font=('SF Pro', 10),
            command=self.toggle_new_folder_entry
        )
        create_folder_check.pack(fill=tk.X, pady=(0, 5))

        self.new_folder_var = tk.StringVar()
        self.new_folder_entry = tk.Entry(
            content_frame,
            textvariable=self.new_folder_var,
            font=('SF Pro', 11),
            bg='white',
            relief=tk.SOLID,
            bd=1,
            state=tk.DISABLED
        )
        self.new_folder_entry.pack(fill=tk.X, pady=(0, 15), ipady=3)

        # 4. TAGS (Optional)
        tags_label = tk.Label(
            content_frame,
            text="Tags (optional):",
            bg='#F7FAFC',
            fg='#2D3748',
            font=('SF Pro', 11, 'bold'),
            anchor='w'
        )
        tags_label.pack(fill=tk.X, pady=(0, 5))

        self.tags_var = tk.StringVar()
        tags_entry = tk.Entry(
            content_frame,
            textvariable=self.tags_var,
            font=('SF Pro', 11),
            bg='white',
            relief=tk.SOLID,
            bd=1
        )
        tags_entry.pack(fill=tk.X, ipady=3)

        # Helper text
        tags_help = tk.Label(
            content_frame,
            text="Separate tags with spaces (e.g., #email #work #template)",
            bg='#F7FAFC',
            fg='#718096',
            font=('SF Pro', 9),
            anchor='w'
        )
        tags_help.pack(fill=tk.X, pady=(2, 0))

        # 5. ACTION BUTTONS
        button_frame = tk.Frame(self, bg='#F7FAFC', pady=15)
        button_frame.pack(fill=tk.X, side=tk.BOTTOM)

        # Cancel button
        cancel_btn = tk.Button(
            button_frame,
            text="Cancel",
            bg='#E2E8F0',
            fg='#2D3748',
            font=('SF Pro', 11),
            relief=tk.FLAT,
            cursor='hand2',
            padx=30,
            pady=8,
            command=self.cancel
        )
        cancel_btn.pack(side=tk.RIGHT, padx=(5, 20))

        # Save button
        save_btn = tk.Button(
            button_frame,
            text="Save Snippet",
            bg='#3182CE',
            fg='white',
            font=('SF Pro', 11, 'bold'),
            relief=tk.FLAT,
            cursor='hand2',
            padx=30,
            pady=8,
            command=self.save_snippet
        )
        save_btn.pack(side=tk.RIGHT, padx=5)

        # Bind Enter key to save
        self.bind('<Return>', lambda e: self.save_snippet())
        self.bind('<Escape>', lambda e: self.cancel())

    def toggle_new_folder_entry(self):
        """Enable/disable new folder entry based on checkbox."""
        if self.create_new_folder_var.get():
            self.new_folder_entry.config(state=tk.NORMAL)
            self.new_folder_entry.focus()
        else:
            self.new_folder_entry.config(state=tk.DISABLED)
            self.new_folder_var.set('')

    def save_snippet(self):
        """Save the snippet with all provided information."""
        # Validate name
        snippet_name = self.name_var.get().strip()
        if not snippet_name:
            messagebox.showerror("Invalid Name", "Please provide a name for the snippet.")
            return

        # Determine folder
        if self.create_new_folder_var.get():
            folder_name = self.new_folder_var.get().strip()
            if not folder_name:
                messagebox.showerror("Invalid Folder", "Please provide a name for the new folder.")
                return
        else:
            folder_name = self.folder_var.get()

        # Parse tags
        tags_str = self.tags_var.get().strip()
        tags = [t.strip() for t in tags_str.split() if t.strip()]

        # Create snippet data
        snippet = {
            'name': snippet_name,
            'content': self.content,
            'tags': tags,
            'created': datetime.now().isoformat(),
            'folder': folder_name
        }

        # Save to clipboard manager
        self._save_to_manager(folder_name, snippet)

        # Show success message
        messagebox.showinfo(
            "Snippet Saved",
            f"✅ Snippet '{snippet_name}' saved to folder '{folder_name}'"
        )

        # Close dialog
        self.destroy()

    def _save_to_manager(self, folder_name: str, snippet: dict):
        """Save snippet to the clipboard manager's storage."""
        # Get or create folder
        if folder_name not in self.clipboard_manager.snippet_folders:
            self.clipboard_manager.snippet_folders[folder_name] = {
                'name': folder_name,
                'snippets': [],
                'created': datetime.now().isoformat()
            }

        # Add snippet to folder
        folder = self.clipboard_manager.snippet_folders[folder_name]
        if 'snippets' not in folder:
            folder['snippets'] = []

        folder['snippets'].append(snippet)

        # Save to disk
        self.clipboard_manager.save_data()

        print(f"✅ Saved snippet '{snippet['name']}' to folder '{folder_name}'")

    def cancel(self):
        """Cancel and close the dialog."""
        self.destroy()

    def center_on_parent(self, parent):
        """Center this dialog on the parent window."""
        self.update_idletasks()

        # Get parent position and size
        parent_x = parent.winfo_x()
        parent_y = parent.winfo_y()
        parent_width = parent.winfo_width()
        parent_height = parent.winfo_height()

        # Get dialog size
        dialog_width = self.winfo_width()
        dialog_height = self.winfo_height()

        # Calculate center position
        x = parent_x + (parent_width - dialog_width) // 2
        y = parent_y + (parent_height - dialog_height) // 2

        self.geometry(f"+{x}+{y}")


if __name__ == "__main__":
    # Test the dialog independently
    root = tk.Tk()
    root.withdraw()

    # Mock clipboard manager for testing
    class MockClipboardManager:
        def __init__(self):
            self.snippet_folders = {
                "Email Templates": {"snippets": []},
                "Code Snippets": {"snippets": []}
            }

        def save_data(self):
            print("Data saved!")

    manager = MockClipboardManager()
    test_content = """Subject: Meeting Request

Dear Team,

I'd like to schedule a meeting to discuss the project timeline.

Best regards"""

    dialog = SnippetSaveDialog(root, test_content, manager)
    root.wait_window(dialog)

    print("Dialog closed")
    print("Folders:", manager.snippet_folders)

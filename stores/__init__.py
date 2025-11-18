"""
Stores package for SimpleCP.

Contains data storage and management classes:
- HistoryStore: Recent clipboard items
- SnippetStore: Organized snippet folders
- ClipboardItem: Data model for individual items
"""

from stores.clipboard_item import ClipboardItem
from stores.history_store import HistoryStore
from stores.snippet_store import SnippetStore

__all__ = ['ClipboardItem', 'HistoryStore', 'SnippetStore']
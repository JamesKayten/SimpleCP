"""
Stores package for SimpleCP.

Contains data storage and management classes:
- ClipboardItem: Data model for individual items
- HistoryStore: Recent clipboard items with auto-folders
- SnippetStore: Organized snippet folders
- SnippetFolder: Individual snippet folder
- TempStore: Temporary storage for undo/redo
- PersistenceManager: Save/load operations

All adapted from Flycut's proven architecture patterns.
"""

from .clipboard_item import ClipboardItem
from .history_store import HistoryStore
from .snippet_store import SnippetStore, SnippetFolder
from .temp_store import TempStore
from .persistence_manager import PersistenceManager

__all__ = [
    'ClipboardItem',
    'HistoryStore',
    'SnippetStore',
    'SnippetFolder',
    'TempStore',
    'PersistenceManager'
]
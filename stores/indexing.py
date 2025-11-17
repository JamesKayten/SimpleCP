"""
Index management utilities for clipboard stores.

Provides functions to rebuild performance indexes after loading from disk.
"""

import hashlib
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from stores.history_store import HistoryStore
    from stores.snippet_store import SnippetStore


def rebuild_history_indexes(history_store: 'HistoryStore'):
    """
    Rebuild history store indexes after loading from disk.

    Args:
        history_store: HistoryStore instance to rebuild indexes for
    """
    history_store._id_index.clear()
    history_store._content_hash.clear()

    for i, item in enumerate(history_store.items):
        history_store._id_index[item.clip_id] = item
        content_hash = hashlib.md5(item.content.encode()).hexdigest()
        history_store._content_hash[content_hash] = i


def rebuild_snippet_indexes(snippet_store: 'SnippetStore'):
    """
    Rebuild snippet store indexes after loading from disk.

    Args:
        snippet_store: SnippetStore instance to rebuild indexes for
    """
    snippet_store._id_index.clear()

    for items in snippet_store.folders.values():
        for item in items:
            snippet_store._id_index[item.clip_id] = item

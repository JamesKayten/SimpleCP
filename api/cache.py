"""
Response caching for menu bar performance.

Caches frequently accessed API responses with automatic invalidation.
"""

from typing import Any, Dict, List, Optional, Callable
from api.models import clipboard_item_to_response, ClipboardItemResponse
import time


class ResponseCache:
    """
    Cache API responses with version-based invalidation.

    For menu bar apps, dropdown opening should be <50ms.
    Caching serialized responses achieves this by avoiding repeated
    ClipboardItem -> JSON conversion.
    """

    def __init__(self):
        """Initialize response cache."""
        # Version counters for invalidation
        self._history_version = 0
        self._snippet_version = 0

        # Cached responses
        self._recent_cache: Optional[List[ClipboardItemResponse]] = None
        self._recent_cache_version = -1

        self._all_history_cache: Optional[List[ClipboardItemResponse]] = None
        self._all_history_cache_version = -1
        self._all_history_limit: Optional[int] = None

        self._snippets_cache: Optional[List[Any]] = None
        self._snippets_cache_version = -1

        # Performance metrics
        self._hits = 0
        self._misses = 0

    def invalidate_history(self):
        """Invalidate history cache when history changes."""
        self._history_version += 1

    def invalidate_snippets(self):
        """Invalidate snippet cache when snippets change."""
        self._snippet_version += 1

    def invalidate_all(self):
        """Invalidate all caches."""
        self.invalidate_history()
        self.invalidate_snippets()

    def get_recent_history(
        self,
        fetch_func: Callable
    ) -> List[ClipboardItemResponse]:
        """
        Get cached recent history or fetch if stale.

        Args:
            fetch_func: Function to fetch items if cache is stale

        Returns:
            List of recent history items (cached or fresh)
        """
        if self._recent_cache_version != self._history_version:
            # Cache miss - fetch and serialize
            self._misses += 1
            items = fetch_func()
            self._recent_cache = [clipboard_item_to_response(item) for item in items]
            self._recent_cache_version = self._history_version
            return self._recent_cache

        # Cache hit
        self._hits += 1
        return self._recent_cache

    def get_all_history(
        self,
        fetch_func: Callable,
        limit: Optional[int] = None
    ) -> List[ClipboardItemResponse]:
        """
        Get cached all history or fetch if stale.

        Args:
            fetch_func: Function to fetch items if cache is stale
            limit: Optional limit (None for all items)

        Returns:
            List of history items (cached or fresh)
        """
        # Check if cache is valid for this limit
        if (self._all_history_cache_version != self._history_version or
            self._all_history_limit != limit):
            # Cache miss
            self._misses += 1
            items = fetch_func(limit)
            self._all_history_cache = [clipboard_item_to_response(item) for item in items]
            self._all_history_cache_version = self._history_version
            self._all_history_limit = limit
            return self._all_history_cache

        # Cache hit
        self._hits += 1
        return self._all_history_cache

    def get_all_snippets(
        self,
        fetch_func: Callable,
        serialize_func: Callable
    ) -> List[Any]:
        """
        Get cached snippets or fetch if stale.

        Args:
            fetch_func: Function to fetch snippets
            serialize_func: Function to serialize folder response

        Returns:
            List of snippet folder responses (cached or fresh)
        """
        if self._snippets_cache_version != self._snippet_version:
            # Cache miss
            self._misses += 1
            snippets_by_folder = fetch_func()
            result = []
            for folder_name, items in snippets_by_folder.items():
                result.append(serialize_func(folder_name, items))
            self._snippets_cache = result
            self._snippets_cache_version = self._snippet_version
            return self._snippets_cache

        # Cache hit
        self._hits += 1
        return self._snippets_cache

    def get_stats(self) -> Dict[str, Any]:
        """Get cache statistics."""
        total = self._hits + self._misses
        hit_rate = (self._hits / total * 100) if total > 0 else 0

        return {
            "hits": self._hits,
            "misses": self._misses,
            "hit_rate": f"{hit_rate:.1f}%",
            "history_version": self._history_version,
            "snippet_version": self._snippet_version
        }

    def clear_stats(self):
        """Reset cache statistics."""
        self._hits = 0
        self._misses = 0


def create_cache_middleware(cache: ResponseCache):
    """
    Create cache invalidation middleware for stores.

    This decorator wraps store delegates to automatically
    invalidate caches when data changes.
    """
    def history_invalidator(event: str, *args):
        """Invalidate history cache on any history change."""
        cache.invalidate_history()

    def snippet_invalidator(event: str, *args):
        """Invalidate snippet cache on any snippet change."""
        cache.invalidate_snippets()

    return history_invalidator, snippet_invalidator

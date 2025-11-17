"""
Advanced Search utilities for SimpleCP
Implements fuzzy search, regex search, and advanced filtering
"""

import re
from typing import List, Dict, Any, Optional, Callable
from datetime import datetime, timedelta
from difflib import SequenceMatcher


class AdvancedSearch:
    """
    Advanced search functionality for clipboard items
    """

    def __init__(self):
        """Initialize advanced search"""
        pass

    def fuzzy_match(self, query: str, text: str, threshold: float = 0.6) -> bool:
        """
        Check if query fuzzy matches text

        Args:
            query: Search query
            text: Text to search in
            threshold: Minimum similarity ratio (0.0 to 1.0)

        Returns:
            True if match found
        """
        if not query or not text:
            return False

        query_lower = query.lower()
        text_lower = text.lower()

        # Exact substring match
        if query_lower in text_lower:
            return True

        # Fuzzy match using SequenceMatcher
        ratio = SequenceMatcher(None, query_lower, text_lower).ratio()
        if ratio >= threshold:
            return True

        # Word-level fuzzy matching
        query_words = query_lower.split()
        text_words = text_lower.split()

        for q_word in query_words:
            for t_word in text_words:
                ratio = SequenceMatcher(None, q_word, t_word).ratio()
                if ratio >= threshold:
                    return True

        return False

    def fuzzy_score(self, query: str, text: str) -> float:
        """
        Calculate fuzzy match score

        Args:
            query: Search query
            text: Text to search in

        Returns:
            Similarity score (0.0 to 1.0)
        """
        if not query or not text:
            return 0.0

        query_lower = query.lower()
        text_lower = text.lower()

        # Exact match bonus
        if query_lower == text_lower:
            return 1.0

        # Substring match bonus
        if query_lower in text_lower:
            return 0.9

        # SequenceMatcher ratio
        return SequenceMatcher(None, query_lower, text_lower).ratio()

    def regex_search(
        self,
        pattern: str,
        text: str,
        case_sensitive: bool = False
    ) -> bool:
        """
        Search using regular expression

        Args:
            pattern: Regex pattern
            text: Text to search in
            case_sensitive: Whether to use case-sensitive matching

        Returns:
            True if pattern matches
        """
        try:
            flags = 0 if case_sensitive else re.IGNORECASE
            return bool(re.search(pattern, text, flags=flags))
        except re.error:
            # Invalid regex pattern
            return False

    def regex_findall(
        self,
        pattern: str,
        text: str,
        case_sensitive: bool = False
    ) -> List[str]:
        """
        Find all matches for regex pattern

        Args:
            pattern: Regex pattern
            text: Text to search in
            case_sensitive: Whether to use case-sensitive matching

        Returns:
            List of matches
        """
        try:
            flags = 0 if case_sensitive else re.IGNORECASE
            return re.findall(pattern, text, flags=flags)
        except re.error:
            return []

    def search_items(
        self,
        items: List[Any],
        query: str,
        search_type: str = "fuzzy",
        fuzzy_threshold: float = 0.6,
        case_sensitive: bool = False,
        search_fields: Optional[List[str]] = None
    ) -> List[Any]:
        """
        Search items with advanced options

        Args:
            items: List of clipboard items
            query: Search query or regex pattern
            search_type: "fuzzy", "regex", or "exact"
            fuzzy_threshold: Minimum similarity for fuzzy search
            case_sensitive: Whether to use case-sensitive matching
            search_fields: Fields to search in (content, snippet_name, tags)

        Returns:
            List of matching items
        """
        if not query:
            return items

        if search_fields is None:
            search_fields = ["content", "snippet_name", "tags"]

        results = []

        for item in items:
            match_found = False

            # Build search text from specified fields
            search_texts = []

            if "content" in search_fields:
                search_texts.append(item.content)

            if "snippet_name" in search_fields and item.snippet_name:
                search_texts.append(item.snippet_name)

            if "tags" in search_fields and item.tags:
                search_texts.append(' '.join(item.tags))

            # Check each field
            for text in search_texts:
                if search_type == "fuzzy":
                    if self.fuzzy_match(query, text, fuzzy_threshold):
                        match_found = True
                        break
                elif search_type == "regex":
                    if self.regex_search(query, text, case_sensitive):
                        match_found = True
                        break
                else:  # exact
                    if case_sensitive:
                        if query in text:
                            match_found = True
                            break
                    else:
                        if query.lower() in text.lower():
                            match_found = True
                            break

            if match_found:
                results.append(item)

        return results

    def filter_by_type(
        self,
        items: List[Any],
        content_types: List[str]
    ) -> List[Any]:
        """
        Filter items by content type

        Args:
            items: List of clipboard items
            content_types: List of types to include (text, url, email, code)

        Returns:
            Filtered items
        """
        return [
            item for item in items
            if item.content_type in content_types
        ]

    def filter_by_date_range(
        self,
        items: List[Any],
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None
    ) -> List[Any]:
        """
        Filter items by date range

        Args:
            items: List of clipboard items
            start_date: Start of date range (inclusive)
            end_date: End of date range (inclusive)

        Returns:
            Filtered items
        """
        results = []

        for item in items:
            try:
                item_date = datetime.fromisoformat(item.timestamp)

                if start_date and item_date < start_date:
                    continue

                if end_date and item_date > end_date:
                    continue

                results.append(item)
            except (ValueError, AttributeError):
                # Invalid timestamp, skip
                continue

        return results

    def filter_by_app(
        self,
        items: List[Any],
        source_apps: List[str]
    ) -> List[Any]:
        """
        Filter items by source application

        Args:
            items: List of clipboard items
            source_apps: List of app names to include

        Returns:
            Filtered items
        """
        return [
            item for item in items
            if item.source_app in source_apps
        ]

    def filter_by_folder(
        self,
        items: List[Any],
        folders: List[str]
    ) -> List[Any]:
        """
        Filter snippets by folder

        Args:
            items: List of clipboard items
            folders: List of folder names

        Returns:
            Filtered items
        """
        return [
            item for item in items
            if item.folder_path in folders
        ]

    def filter_by_tags(
        self,
        items: List[Any],
        tags: List[str],
        match_all: bool = False
    ) -> List[Any]:
        """
        Filter items by tags

        Args:
            items: List of clipboard items
            tags: List of tags to match
            match_all: If True, item must have all tags; if False, any tag

        Returns:
            Filtered items
        """
        results = []

        for item in items:
            if not item.tags:
                continue

            if match_all:
                # Item must have all specified tags
                if all(tag in item.tags for tag in tags):
                    results.append(item)
            else:
                # Item must have at least one tag
                if any(tag in item.tags for tag in tags):
                    results.append(item)

        return results

    def advanced_search(
        self,
        items: List[Any],
        query: Optional[str] = None,
        search_type: str = "fuzzy",
        fuzzy_threshold: float = 0.6,
        case_sensitive: bool = False,
        content_types: Optional[List[str]] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        source_apps: Optional[List[str]] = None,
        folders: Optional[List[str]] = None,
        tags: Optional[List[str]] = None,
        match_all_tags: bool = False,
        sort_by: Optional[str] = None,
        reverse: bool = False
    ) -> List[Any]:
        """
        Perform advanced search with multiple filters

        Args:
            items: List of clipboard items
            query: Search query
            search_type: "fuzzy", "regex", or "exact"
            fuzzy_threshold: Minimum similarity for fuzzy search
            case_sensitive: Whether to use case-sensitive matching
            content_types: Filter by content types
            start_date: Filter by start date
            end_date: Filter by end date
            source_apps: Filter by source apps
            folders: Filter by folders
            tags: Filter by tags
            match_all_tags: Whether to match all tags or any tag
            sort_by: Field to sort by (timestamp, content_type, source_app)
            reverse: Whether to reverse sort order

        Returns:
            List of matching items
        """
        results = items.copy()

        # Apply search query
        if query:
            results = self.search_items(
                results,
                query,
                search_type,
                fuzzy_threshold,
                case_sensitive
            )

        # Apply filters
        if content_types:
            results = self.filter_by_type(results, content_types)

        if start_date or end_date:
            results = self.filter_by_date_range(results, start_date, end_date)

        if source_apps:
            results = self.filter_by_app(results, source_apps)

        if folders:
            results = self.filter_by_folder(results, folders)

        if tags:
            results = self.filter_by_tags(results, tags, match_all_tags)

        # Sort results
        if sort_by:
            results = self.sort_items(results, sort_by, reverse)

        return results

    def sort_items(
        self,
        items: List[Any],
        sort_by: str,
        reverse: bool = False
    ) -> List[Any]:
        """
        Sort items by field

        Args:
            items: List of clipboard items
            sort_by: Field to sort by
            reverse: Whether to reverse order

        Returns:
            Sorted items
        """
        if sort_by == "timestamp":
            return sorted(
                items,
                key=lambda x: x.timestamp,
                reverse=reverse
            )
        elif sort_by == "content_type":
            return sorted(
                items,
                key=lambda x: x.content_type,
                reverse=reverse
            )
        elif sort_by == "source_app":
            return sorted(
                items,
                key=lambda x: x.source_app or "",
                reverse=reverse
            )
        elif sort_by == "content_length":
            return sorted(
                items,
                key=lambda x: len(x.content),
                reverse=reverse
            )
        else:
            return items

    def highlight_matches(
        self,
        text: str,
        query: str,
        search_type: str = "fuzzy",
        case_sensitive: bool = False
    ) -> List[Dict[str, Any]]:
        """
        Find and highlight matching portions of text

        Args:
            text: Text to search in
            query: Search query
            search_type: "fuzzy", "regex", or "exact"
            case_sensitive: Whether to use case-sensitive matching

        Returns:
            List of match positions with start, end, and matched text
        """
        matches = []

        if search_type == "regex":
            try:
                flags = 0 if case_sensitive else re.IGNORECASE
                for match in re.finditer(query, text, flags=flags):
                    matches.append({
                        "start": match.start(),
                        "end": match.end(),
                        "text": match.group()
                    })
            except re.error:
                pass
        else:  # exact or fuzzy
            search_query = query if case_sensitive else query.lower()
            search_text = text if case_sensitive else text.lower()

            # Find exact matches
            start = 0
            while True:
                pos = search_text.find(search_query, start)
                if pos == -1:
                    break

                matches.append({
                    "start": pos,
                    "end": pos + len(query),
                    "text": text[pos:pos + len(query)]
                })

                start = pos + 1

        return matches

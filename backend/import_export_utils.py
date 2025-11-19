"""Import/export utilities for clipboard manager."""

from datetime import datetime
from typing import Dict, Any, List
from stores.clipboard_item import ClipboardItem


def export_snippets(snippet_store) -> Dict[str, Any]:
    """Export all snippets from a snippet store."""
    all_snippets = []
    for folder, items in snippet_store.folders.items():
        for item in items:
            all_snippets.append(item.to_dict())
    return {
        "version": "1.0",
        "export_date": datetime.now().isoformat(),
        "snippets": all_snippets,
        "metadata": {"folder_count": len(snippet_store.folders)},
    }


def import_snippets(
    snippet_store, import_data: Dict[str, Any], auto_save_callback=None
) -> bool:
    """Import snippets into a snippet store."""
    try:
        snippets = import_data.get("snippets", [])
        for snippet_data in snippets:
            item = ClipboardItem.from_dict(snippet_data)
            folder = item.folder_path or "Imported"
            snippet_store.add_snippet(folder, item)
        if auto_save_callback:
            auto_save_callback()
        return True
    except Exception as e:
        print(f"Error importing snippets: {e}")
        return False

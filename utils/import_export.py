"""
Import/Export utilities for SimpleCP
Handles data export to various formats and import from other sources
"""

import json
import csv
from pathlib import Path
from typing import List, Dict, Any, Optional
from datetime import datetime
import zipfile
import io


class ImportExportManager:
    """
    Manages import/export operations for clipboard data
    """

    def __init__(self, clipboard_manager):
        """
        Initialize import/export manager

        Args:
            clipboard_manager: ClipboardManager instance
        """
        self.manager = clipboard_manager

    def export_to_json(
        self,
        items: List[Any],
        filepath: Optional[str] = None,
        pretty: bool = True
    ) -> str:
        """
        Export items to JSON format

        Args:
            items: List of clipboard items
            filepath: Output file path (optional)
            pretty: Whether to format JSON prettily

        Returns:
            JSON string
        """
        data = {
            "export_date": datetime.now().isoformat(),
            "export_type": "simplecp_export",
            "version": "1.0",
            "item_count": len(items),
            "items": [self._item_to_dict(item) for item in items]
        }

        json_str = json.dumps(data, indent=2 if pretty else None)

        if filepath:
            with open(filepath, 'w') as f:
                f.write(json_str)

        return json_str

    def export_to_csv(
        self,
        items: List[Any],
        filepath: Optional[str] = None
    ) -> str:
        """
        Export items to CSV format

        Args:
            items: List of clipboard items
            filepath: Output file path (optional)

        Returns:
            CSV string
        """
        output = io.StringIO()
        writer = csv.writer(output)

        # Write header
        writer.writerow([
            'Content',
            'Type',
            'Source App',
            'Timestamp',
            'Clip ID',
            'Snippet Name',
            'Folder',
            'Tags'
        ])

        # Write items
        for item in items:
            writer.writerow([
                item.content[:500],  # Limit content length
                item.content_type,
                item.source_app or '',
                item.timestamp,
                item.clip_id,
                item.snippet_name or '',
                item.folder_path or '',
                ','.join(item.tags) if item.tags else ''
            ])

        csv_str = output.getvalue()

        if filepath:
            with open(filepath, 'w') as f:
                f.write(csv_str)

        return csv_str

    def export_to_txt(
        self,
        items: List[Any],
        filepath: Optional[str] = None,
        separator: str = "\n---\n"
    ) -> str:
        """
        Export items to plain text format

        Args:
            items: List of clipboard items
            filepath: Output file path (optional)
            separator: Separator between items

        Returns:
            Text string
        """
        lines = [
            f"SimpleCP Export - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            f"Total Items: {len(items)}",
            "=" * 60,
            ""
        ]

        for i, item in enumerate(items, 1):
            lines.append(f"Item #{i}")
            lines.append(f"Time: {item.timestamp}")
            lines.append(f"Type: {item.content_type}")
            if item.source_app:
                lines.append(f"Source: {item.source_app}")
            if item.snippet_name:
                lines.append(f"Name: {item.snippet_name}")
            if item.folder_path:
                lines.append(f"Folder: {item.folder_path}")
            if item.tags:
                lines.append(f"Tags: {', '.join(item.tags)}")
            lines.append("")
            lines.append(item.content)
            lines.append(separator)

        text_str = '\n'.join(lines)

        if filepath:
            with open(filepath, 'w') as f:
                f.write(text_str)

        return text_str

    def export_history(
        self,
        format: str = "json",
        filepath: Optional[str] = None,
        limit: Optional[int] = None
    ) -> str:
        """
        Export clipboard history

        Args:
            format: Export format (json, csv, txt)
            filepath: Output file path (optional)
            limit: Maximum number of items to export

        Returns:
            Exported data string
        """
        items = self.manager.history_store.get_all_items()

        if limit:
            items = items[:limit]

        if format == "json":
            return self.export_to_json(items, filepath)
        elif format == "csv":
            return self.export_to_csv(items, filepath)
        elif format == "txt":
            return self.export_to_txt(items, filepath)
        else:
            raise ValueError(f"Unsupported format: {format}")

    def export_snippets(
        self,
        format: str = "json",
        filepath: Optional[str] = None,
        folder: Optional[str] = None
    ) -> str:
        """
        Export snippets

        Args:
            format: Export format (json, csv, txt)
            filepath: Output file path (optional)
            folder: Specific folder to export (optional)

        Returns:
            Exported data string
        """
        if folder:
            items = self.manager.snippet_store.folders.get(folder, [])
        else:
            items = []
            for folder_items in self.manager.snippet_store.folders.values():
                items.extend(folder_items)

        if format == "json":
            return self.export_to_json(items, filepath)
        elif format == "csv":
            return self.export_to_csv(items, filepath)
        elif format == "txt":
            return self.export_to_txt(items, filepath)
        else:
            raise ValueError(f"Unsupported format: {format}")

    def export_selected(
        self,
        clip_ids: List[str],
        format: str = "json",
        filepath: Optional[str] = None
    ) -> str:
        """
        Export selected items by ID

        Args:
            clip_ids: List of clip IDs to export
            format: Export format (json, csv, txt)
            filepath: Output file path (optional)

        Returns:
            Exported data string
        """
        items = []

        # Search in history
        for item in self.manager.history_store.get_all_items():
            if item.clip_id in clip_ids:
                items.append(item)

        # Search in snippets
        for folder_items in self.manager.snippet_store.folders.values():
            for item in folder_items:
                if item.clip_id in clip_ids:
                    items.append(item)

        if format == "json":
            return self.export_to_json(items, filepath)
        elif format == "csv":
            return self.export_to_csv(items, filepath)
        elif format == "txt":
            return self.export_to_txt(items, filepath)
        else:
            raise ValueError(f"Unsupported format: {format}")

    def create_backup(self, filepath: str) -> str:
        """
        Create full backup of all data

        Args:
            filepath: Output zip file path

        Returns:
            Path to created backup
        """
        backup_dir = Path(self.manager.data_dir)

        with zipfile.ZipFile(filepath, 'w', zipfile.ZIP_DEFLATED) as zipf:
            # Add all JSON files
            for json_file in backup_dir.glob("*.json"):
                zipf.write(json_file, json_file.name)

            # Add metadata
            metadata = {
                "backup_date": datetime.now().isoformat(),
                "version": "1.0",
                "files_included": [f.name for f in backup_dir.glob("*.json")]
            }
            zipf.writestr("backup_metadata.json", json.dumps(metadata, indent=2))

        return filepath

    def restore_backup(self, filepath: str) -> Dict[str, Any]:
        """
        Restore from backup file

        Args:
            filepath: Path to backup zip file

        Returns:
            Dictionary with restore results
        """
        backup_dir = Path(self.manager.data_dir)
        restored_files = []

        with zipfile.ZipFile(filepath, 'r') as zipf:
            # Extract all files
            for file_info in zipf.filelist:
                if file_info.filename.endswith('.json') and file_info.filename != 'backup_metadata.json':
                    zipf.extract(file_info, backup_dir)
                    restored_files.append(file_info.filename)

        # Reload data
        self.manager.load_stores()

        return {
            "success": True,
            "restored_files": restored_files,
            "restore_date": datetime.now().isoformat()
        }

    def import_from_json(self, filepath: str, merge: bool = True) -> Dict[str, Any]:
        """
        Import data from JSON file

        Args:
            filepath: Path to JSON file
            merge: If True, merge with existing data; if False, replace

        Returns:
            Import results
        """
        with open(filepath, 'r') as f:
            data = json.load(f)

        items_imported = 0
        errors = []

        # Validate format
        if "items" not in data:
            raise ValueError("Invalid JSON format: missing 'items' key")

        for item_data in data["items"]:
            try:
                # Create clipboard item
                from stores.clipboard_item import ClipboardItem

                item = ClipboardItem(
                    content=item_data["content"],
                    timestamp=item_data.get("timestamp"),
                    clip_id=item_data.get("clip_id"),
                    content_type=item_data.get("content_type"),
                    source_app=item_data.get("source_app")
                )

                # Check if it's a snippet
                if item_data.get("snippet_name"):
                    item.has_name = True
                    item.snippet_name = item_data["snippet_name"]
                    item.folder_path = item_data.get("folder_path", "Imported")
                    item.tags = item_data.get("tags", [])

                    # Add to snippets
                    folder = item.folder_path
                    if folder not in self.manager.snippet_store.folders:
                        self.manager.snippet_store.folders[folder] = []

                    # Check for duplicates if merging
                    if merge:
                        existing_ids = [i.clip_id for i in self.manager.snippet_store.folders[folder]]
                        if item.clip_id not in existing_ids:
                            self.manager.snippet_store.folders[folder].append(item)
                            items_imported += 1
                    else:
                        self.manager.snippet_store.folders[folder].append(item)
                        items_imported += 1
                else:
                    # Add to history
                    if merge:
                        self.manager.history_store.insert(item)
                    else:
                        self.manager.history_store.items.append(item)
                    items_imported += 1

            except Exception as e:
                errors.append(f"Error importing item: {str(e)}")

        # Save changes
        self.manager.save_stores()

        return {
            "success": True,
            "items_imported": items_imported,
            "errors": errors,
            "merge_mode": merge
        }

    def import_from_csv(self, filepath: str, merge: bool = True) -> Dict[str, Any]:
        """
        Import data from CSV file

        Args:
            filepath: Path to CSV file
            merge: If True, merge with existing data; if False, replace

        Returns:
            Import results
        """
        from stores.clipboard_item import ClipboardItem

        items_imported = 0
        errors = []

        with open(filepath, 'r') as f:
            reader = csv.DictReader(f)

            for row in reader:
                try:
                    item = ClipboardItem(
                        content=row["Content"],
                        timestamp=row.get("Timestamp"),
                        clip_id=row.get("Clip ID"),
                        content_type=row.get("Type"),
                        source_app=row.get("Source App")
                    )

                    # Check if it's a snippet
                    if row.get("Snippet Name"):
                        item.has_name = True
                        item.snippet_name = row["Snippet Name"]
                        item.folder_path = row.get("Folder", "Imported")
                        tags_str = row.get("Tags", "")
                        item.tags = [t.strip() for t in tags_str.split(',') if t.strip()]

                        # Add to snippets
                        folder = item.folder_path
                        if folder not in self.manager.snippet_store.folders:
                            self.manager.snippet_store.folders[folder] = []

                        if merge:
                            existing_ids = [i.clip_id for i in self.manager.snippet_store.folders[folder]]
                            if item.clip_id not in existing_ids:
                                self.manager.snippet_store.folders[folder].append(item)
                                items_imported += 1
                        else:
                            self.manager.snippet_store.folders[folder].append(item)
                            items_imported += 1
                    else:
                        # Add to history
                        if merge:
                            self.manager.history_store.insert(item)
                        else:
                            self.manager.history_store.items.append(item)
                        items_imported += 1

                except Exception as e:
                    errors.append(f"Error importing row: {str(e)}")

        # Save changes
        self.manager.save_stores()

        return {
            "success": True,
            "items_imported": items_imported,
            "errors": errors,
            "merge_mode": merge
        }

    def _item_to_dict(self, item) -> Dict[str, Any]:
        """Convert clipboard item to dictionary"""
        return {
            "content": item.content,
            "timestamp": item.timestamp,
            "clip_id": item.clip_id,
            "content_type": item.content_type,
            "source_app": item.source_app,
            "snippet_name": item.snippet_name,
            "folder_path": item.folder_path,
            "tags": item.tags,
            "has_name": item.has_name
        }

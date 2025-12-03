# Adapting Flycut's Architecture for SimpleCP

Based on analysis of the mature Flycut codebase, here are the proven patterns we should adapt for our Python implementation.

## Key Flycut Patterns to Adopt

### 1. FlycutClipping → ClipboardItem (Enhanced)

**Flycut's Data Model:**
```objc
@interface FlycutClipping : NSObject {
    NSString * clipContents;        // The actual text
    NSString * clipType;            // Type of content
    int clipDisplayLength;          // Display length setting
    NSString * clipDisplayString;   // Processed for display
    BOOL clipHasName;              // Whether it's a named snippet
    NSString * appLocalizedName;    // Source app name
    NSString * appBundleURL;        // Source app bundle
    NSInteger clipTimestamp;        // Creation time
}
```

**Our Python Adaptation:**
```python
class ClipboardItem:
    def __init__(self, content: str, content_type: str = "text"):
        self.content = content
        self.content_type = content_type  # "text", "url", "email", "code", etc.
        self.timestamp = datetime.now()

        # Display properties (from Flycut)
        self.display_length = 50  # Configurable
        self.display_string = self._create_display_string()

        # Snippet properties (from Flycut's clipHasName)
        self.has_name = False
        self.snippet_name = None
        self.folder_path = None  # Our folder organization
        self.tags = []  # Our enhancement

        # Source tracking (from Flycut)
        self.source_app = self._detect_source_app()

        # Unique ID for tracking
        self.clip_id = self._generate_id()

    def _create_display_string(self):
        # Flycut's display string logic adapted
        clean_text = self.content.replace('\n', ' ').replace('\t', ' ').strip()
        if len(clean_text) <= self.display_length:
            return clean_text
        return clean_text[:self.display_length-3] + "..."

    def make_snippet(self, name: str, folder: str, tags: list = None):
        # Convert history item to snippet (Flycut's clipHasName pattern)
        self.has_name = True
        self.snippet_name = name
        self.folder_path = folder
        self.tags = tags or []
        return self
```

### 2. FlycutOperator → ClipboardManager (Multi-Store)

**Flycut's Store Management:**
```objc
@interface FlycutOperator : NSObject {
    FlycutStore *clippingStore;     // Regular history
    FlycutStore *favoritesStore;    // Saved snippets
    FlycutStore *stashedStore;      // Temporary storage
    int stackPosition;              // Current position
}
```

**Our Python Adaptation:**
```python
class ClipboardManager:
    def __init__(self):
        # Multiple stores like Flycut
        self.history_store = HistoryStore(max_items=50)      # clippingStore
        self.snippet_store = SnippetStore()                  # favoritesStore
        self.temp_store = TempStore()                        # stashedStore (for undo)

        # Navigation (from Flycut's stackPosition)
        self.current_position = 0

        # Display settings (from Flycut)
        self.display_num = 10          # How many to show
        self.display_length = 50       # Char limit

        # Flycut's save management
        self.modified_since_save = False
        self.auto_save_enabled = True

    def add_clip(self, content: str) -> ClipboardItem:
        # Flycut's addClipping pattern
        clip = ClipboardItem(content)

        # Check for duplicates (Flycut's removeDuplicates)
        existing_index = self.history_store.find_duplicate(clip)
        if existing_index >= 0:
            self.history_store.move_to_top(existing_index)
            return self.history_store.get_item(0)

        # Add to history
        self.history_store.insert(clip, 0)
        self.modified_since_save = True

        # Auto-save if enabled
        if self.auto_save_enabled:
            self.save_stores()

        return clip

    def save_as_snippet(self, clip: ClipboardItem, name: str, folder: str, tags: list = None):
        # Convert history item to snippet (Flycut's favorites pattern)
        snippet = clip.make_snippet(name, folder, tags)
        self.snippet_store.add_to_folder(folder, snippet)
        self.modified_since_save = True
        return snippet
```

### 3. FlycutStore → HistoryStore/SnippetStore (Delegate Pattern)

**Flycut's Store Architecture:**
```objc
@interface FlycutStore : NSObject {
    int jcRememberNum;              // Max items to remember
    int jcDisplayNum;               // How many to display
    int jcDisplayLen;               // Display character limit
    bool modifiedSinceLastSaveStore; // Dirty flag
    NSMutableArray *jcList;         // The actual items
}
```

**Our Python Adaptation:**
```python
class HistoryStore:
    def __init__(self, max_items: int = 50, display_count: int = 10, display_length: int = 50):
        # Flycut's core settings
        self.max_items = max_items              # jcRememberNum
        self.display_count = display_count      # jcDisplayNum
        self.display_length = display_length    # jcDisplayLen
        self.modified = False                   # modifiedSinceLastSaveStore

        # Storage
        self.items = []                         # jcList

        # Flycut's delegate pattern for UI updates
        self.delegates = []

    def insert(self, item: ClipboardItem, index: int = 0):
        # Flycut's insertClipping pattern
        self.notify_delegates('will_insert', index)
        self.items.insert(index, item)

        # Enforce size limit (Flycut's trimming)
        if len(self.items) > self.max_items:
            removed = self.items.pop()
            self.notify_delegates('did_delete', len(self.items))

        self.modified = True
        self.notify_delegates('did_insert', index)

    def get_auto_folders(self) -> list:
        # Our enhancement: auto-generate folder ranges like "11-20", "21-30"
        folders = []
        total_items = len(self.items)

        # Skip first display_count items (they show directly)
        start_index = self.display_count

        while start_index < total_items:
            end_index = min(start_index + self.display_count - 1, total_items - 1)
            folder_name = f"{start_index + 1} - {end_index + 1}"
            folder_items = self.items[start_index:end_index + 1]
            folders.append({"name": folder_name, "items": folder_items})
            start_index = end_index + 1

        return folders

class SnippetStore:
    def __init__(self):
        self.folders = {}  # folder_name -> list of ClipboardItem
        self.modified = False
        self.delegates = []

    def create_folder(self, folder_name: str):
        if folder_name not in self.folders:
            self.folders[folder_name] = []
            self.modified = True
            self.notify_delegates('folder_created', folder_name)

    def add_to_folder(self, folder_name: str, item: ClipboardItem):
        if folder_name not in self.folders:
            self.create_folder(folder_name)

        self.folders[folder_name].append(item)
        self.modified = True
        self.notify_delegates('item_added', folder_name, item)
```

### 4. Flycut's Persistence Pattern

**Flycut's Save/Load:**
```objc
-(void) saveEngine;                  // Save all stores
-(bool) loadEngineFromPList;         // Load from storage
```

**Our Python Adaptation:**
```python
class PersistenceManager:
    def __init__(self, data_dir: str):
        self.data_dir = data_dir
        self.history_file = os.path.join(data_dir, "history.json")
        self.snippets_file = os.path.join(data_dir, "snippets.json")

    def save_stores(self, history_store: HistoryStore, snippet_store: SnippetStore):
        # Flycut's saveEngine pattern
        try:
            # Save history
            history_data = [item.to_dict() for item in history_store.items]
            with open(self.history_file, 'w') as f:
                json.dump(history_data, f, indent=2)

            # Save snippets
            snippet_data = {}
            for folder_name, items in snippet_store.folders.items():
                snippet_data[folder_name] = [item.to_dict() for item in items]

            with open(self.snippets_file, 'w') as f:
                json.dump(snippet_data, f, indent=2)

            # Clear dirty flags
            history_store.modified = False
            snippet_store.modified = False

        except Exception as e:
            print(f"Save error: {e}")

    def load_stores(self) -> tuple[list, dict]:
        # Flycut's loadEngineFromPList pattern
        history_items = []
        snippet_folders = {}

        try:
            # Load history
            if os.path.exists(self.history_file):
                with open(self.history_file, 'r') as f:
                    data = json.load(f)
                history_items = [ClipboardItem.from_dict(item_data) for item_data in data]

            # Load snippets
            if os.path.exists(self.snippets_file):
                with open(self.snippets_file, 'r') as f:
                    data = json.load(f)
                for folder_name, items_data in data.items():
                    snippet_folders[folder_name] = [ClipboardItem.from_dict(item_data) for item_data in items_data]

        except Exception as e:
            print(f"Load error: {e}")

        return history_items, snippet_folders
```

## Key Takeaways from Flycut

1. **Separate stores** for different purposes (history vs snippets)
2. **Rich data model** with display properties and metadata
3. **Delegate pattern** for UI updates
4. **Configurable limits** and display settings
5. **Proper persistence** with dirty flag tracking
6. **Duplicate handling** and list management
7. **Source app tracking** for better organization

## Implementation Priority for SimpleCP

1. **Phase 1**: Implement enhanced ClipboardItem with Flycut's metadata
2. **Phase 2**: Multi-store ClipboardManager like FlycutOperator
3. **Phase 3**: Auto-folder generation for history (our enhancement)
4. **Phase 4**: Snippet workflow using Flycut's favorites pattern
5. **Phase 5**: Persistence using Flycut's save/load pattern

This proven architecture from Flycut will make SimpleCP much more robust and feature-complete!
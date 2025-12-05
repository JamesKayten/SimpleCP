# SimpleCP Developer Guide

## Quick Start

### Requirements

- macOS 13.0+ (Ventura or later)
- Xcode 15.0+
- Swift 5.9+
- Python 3.8+

### Building the Project

```bash
# Clone the repository
git clone <repository-url>
cd SimpleCP

# Build with Swift Package Manager
swift build

# Or open in Xcode
open Package.swift
```

### Running Tests

```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter BackendServiceTests
```

### Project Structure

```
SimpleCP/
├── Package.swift                 # Swift Package configuration
├── Sources/SimpleCP/
│   ├── SimpleCPApp.swift        # App entry point
│   ├── AppDelegate.swift        # Lifecycle management
│   ├── BackendService.swift     # Backend process management
│   ├── BackendService+Monitoring.swift  # Health checks
│   ├── ClipboardManager.swift   # Clipboard operations
│   ├── ClipboardManager+Snippets.swift  # Snippet management
│   ├── DataPersistence.swift    # File-based storage
│   ├── SecurityConsiderations.swift     # Security utilities
│   ├── ContentView.swift        # Main UI
│   ├── SettingsWindow.swift     # Settings UI
│   ├── SettingsViews.swift      # Settings components
│   ├── RecentClipsColumn.swift  # Recent clips view
│   ├── AppError.swift           # Error handling
│   └── APIClient+Folders.swift  # API client
├── BackendServiceTests.swift    # Unit tests
├── IMPROVEMENTS.md              # Improvement documentation
├── CHANGELOG.md                 # Version history
└── backend/                     # Python backend
    └── main.py                  # FastAPI server
```

## Development Workflow

### 1. Backend Development

Start the Python backend manually for development:

```bash
cd backend
python3 main.py
```

The backend runs on `http://localhost:8000` by default.

### 2. Frontend Development

Open the project in Xcode and run. The frontend will:
1. Automatically detect and connect to the backend
2. Show connection status in the UI
3. Retry with exponential backoff if backend isn't ready

### 3. Debugging

#### Backend Logs

```bash
# Check backend process
lsof -i :8000

# View backend PID
cat ~/Library/Caches/TemporaryItems/.../com.simplecp.backend.pid

# Kill backend if stuck
lsof -ti:8000 | xargs kill -9
```

#### Frontend Logs

Use Console.app and filter by "com.simplecp.app"

Or in Xcode:
- Debug → Open System Log
- Filter: "simplecp"

### 4. Testing

#### Unit Tests

```swift
@Test("Test description")
func testSomething() async throws {
    // Your test code
    #expect(condition)
}
```

Run tests:
- Xcode: ⌘U
- Terminal: `swift test`

## Key Concepts

### 1. Connection State Management

The app tracks backend connection state:

```swift
enum BackendConnectionState {
    case disconnected
    case connecting
    case connected
    case error(String)
}
```

Always check `backendService.connectionState` before making API calls.

### 2. Data Persistence

Use `DataPersistenceManager` for large data:

```swift
// Save
try await DataPersistenceManager.shared.save(
    data,
    filename: "my_data.json"
)

// Load
let data = try await DataPersistenceManager.shared.load(
    filename: "my_data.json",
    as: MyType.self
)
```

### 3. Security

Check content before storing:

```swift
if SecurityManager.shared.shouldStoreClipboardContent(content) {
    // Safe to store
}
```

### 4. Exponential Backoff

For any retry logic:

```swift
for attempt in 0..<maxAttempts {
    let delay = min(baseDelay * pow(2.0, Double(attempt)), maxDelay)
    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    // Retry operation
}
```

## Common Tasks

### Adding a New Setting

1. Add `@AppStorage` property:
```swift
@AppStorage("mySettingKey") var mySetting: Bool = false
```

2. Add UI in `SettingsViews.swift`:
```swift
Toggle("My Setting", isOn: $mySetting)
```

3. Use in code:
```swift
if mySetting {
    // Do something
}
```

### Adding a New API Endpoint

1. Add to backend (`backend/main.py`):
```python
@app.get("/api/my-endpoint")
async def my_endpoint():
    return {"result": "data"}
```

2. Add extension to `APIClient`:
```swift
extension APIClient {
    func fetchMyData() async throws -> MyData {
        return try await executeWithRetry(operation: "Fetch my data") {
            let url = URL(string: "\(self.baseURL)/api/my-endpoint")!
            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode(MyData.self, from: data)
        }
    }
}
```

### Adding a New View

1. Create SwiftUI view:
```swift
struct MyView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @EnvironmentObject var backendService: BackendService
    
    var body: some View {
        // Your UI
    }
}
```

2. Add to `ContentView` or another parent view

3. Provide environment objects:
```swift
MyView()
    .environmentObject(clipboardManager)
    .environmentObject(backendService)
```

## Best Practices

### 1. Always Use Main Actor for UI Updates

```swift
Task { @MainActor in
    self.isLoading = true
    // Update UI
}
```

### 2. Handle Errors Gracefully

```swift
do {
    try await someOperation()
} catch {
    logger.error("Operation failed: \(error)")
    // Show user-friendly error
    showError = true
    errorMessage = error.localizedDescription
}
```

### 3. Use Structured Logging

```swift
logger.info("✅ Success: \(details)")
logger.warning("⚠️ Warning: \(details)")
logger.error("❌ Error: \(details)")
logger.debug("🔍 Debug: \(details)")
```

### 4. Sanitize Sensitive Content

```swift
let sanitized = SecurityManager.shared.sanitizeContent(
    content,
    redactionStyle: .partial
)
logger.debug("Content: \(sanitized)")
```

### 5. Test with Different Backend States

- Backend not running
- Backend starting up
- Backend healthy
- Backend crashed
- Port occupied by another process

## Performance Tips

### 1. Lazy Loading

Load data only when needed:

```swift
@State private var items: [Item] = []

.onAppear {
    loadItems()
}
```

### 2. Debouncing

For search and frequent updates:

```swift
.onChange(of: searchText) { newValue in
    searchDebounceTask?.cancel()
    searchDebounceTask = Task {
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
        performSearch(newValue)
    }
}
```

### 3. Background Tasks

For long operations:

```swift
Task.detached {
    let result = await expensiveOperation()
    await MainActor.run {
        self.result = result
    }
}
```

## Troubleshooting

### Backend Won't Start

1. Check if port is in use: `lsof -i :8000`
2. Check Python version: `python3 --version`
3. Check backend logs in Console.app
4. Try manual start: `cd backend && python3 main.py`

### Frontend Can't Connect

1. Check connection status indicator in UI
2. Try "Restart Backend" button
3. Check firewall settings
4. Verify backend is running: `curl http://localhost:8000/health`

### Tests Failing

1. Make sure no other instance is running
2. Clean build folder: `swift package clean`
3. Reset test environment
4. Check for port conflicts

### Performance Issues

1. Check clipboard history size
2. Monitor memory usage in Activity Monitor
3. Check for timer leaks
4. Profile with Instruments

## Contributing

### Code Style

- Use SwiftLint (if configured)
- Follow Swift API Design Guidelines
- Write descriptive commit messages
- Add tests for new features
- Update documentation

### Pull Request Process

1. Create feature branch
2. Make changes with tests
3. Update CHANGELOG.md
4. Submit PR with description
5. Address review feedback

## Resources

### Apple Documentation
- [SwiftUI](https://developer.apple.com/documentation/swiftui)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Swift Testing](https://developer.apple.com/documentation/testing)

### Swift Package Manager
- [SPM Documentation](https://swift.org/package-manager/)
- [Package Manifest API](https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html)

### Community
- [Swift Forums](https://forums.swift.org)
- [Apple Developer Forums](https://developer.apple.com/forums/)

## License

[Your license here]

---

**Happy Coding! 🚀**

For questions or issues, please check existing issues or create a new one.

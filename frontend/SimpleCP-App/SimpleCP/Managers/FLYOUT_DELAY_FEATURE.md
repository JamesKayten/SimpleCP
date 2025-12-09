# Flyout Delay Configuration Feature

## Summary
Added user-configurable delays for all flyout displays in SimpleCP, allowing users to customize how long they need to hover before previews and flyouts appear.

## Changes Made

### 1. ClipboardManager.swift
Added three new computed properties to manage flyout delays:

```swift
/// Delay in seconds before showing clip preview popovers (default: 0.7s)
var clipPreviewDelay: TimeInterval

/// Delay in seconds before showing clip group flyouts (default: 0.5s)
var clipGroupFlyoutDelay: TimeInterval

/// Delay in seconds before showing folder flyouts (default: 1.0s)
var folderFlyoutDelay: TimeInterval
```

These properties:
- Store values in UserDefaults
- Provide sensible defaults (0.7s, 0.5s, and 1.0s respectively)
- Are accessible throughout the app via the ClipboardManager instance

### 2. RecentClipsColumn.swift
Updated two components to use configurable delays:

**ClipItemRow:**
- Added `@AppStorage("clipPreviewDelay")` property
- Changed hardcoded 0.7s delay to use `clipPreviewDelay`

**HistoryGroupDisclosure:**
- Added `@AppStorage("clipGroupFlyoutDelay")` property
- Changed hardcoded 0.5s delay to use `clipGroupFlyoutDelay`

### 3. FolderView.swift
Updated the main FolderView component:
- Added `@AppStorage("folderFlyoutDelay")` property
- Changed hardcoded 1.0s delay to use `folderFlyoutDelay`

### 4. SettingsWindow.swift
Enhanced the settings interface:

**Added storage properties:**
```swift
@AppStorage("clipPreviewDelay") private var clipPreviewDelay = 0.7
@AppStorage("clipGroupFlyoutDelay") private var clipGroupFlyoutDelay = 0.5
@AppStorage("folderFlyoutDelay") private var folderFlyoutDelay = 1.0
```

**Created new settings views:**
- `GeneralSettingsView` - Launch options, window settings, backend API
- `AppearanceSettingsView` - Theme, opacity, fonts, and **flyout delays**
- `ClipsSettingsView` - History size configuration
- `SnippetsSettingsView` - Snippet management info

**Flyout delay controls in AppearanceSettingsView:**
- Sliders for each delay type (range: 0.1s - 2.0s)
- Real-time display of current delay values
- Integrated with existing "Show snippet previews" toggle
- Clear labels and helpful descriptions

## User Experience

### Settings Location
Users can access these settings via:
1. Open Settings window (⌘,)
2. Navigate to "Appearance" tab
3. Scroll to "Flyout & Preview Delays" section

### Available Controls

| Control | Range | Default | Description |
|---------|-------|---------|-------------|
| Clip preview delay | 0.1s - 2.0s | 0.7s | How long to hover over a clip before showing its full content preview |
| Clip group flyout delay | 0.1s - 2.0s | 0.5s | How long to hover over a clip group (e.g., "11-20") before showing the flyout |
| Folder flyout delay | 0.1s - 2.0s | 1.0s | How long to hover over a folder before showing its snippets flyout |

### Use Cases
- **Faster navigation**: Users who prefer quick access can reduce delays (0.1s - 0.3s)
- **Prevent accidental triggers**: Users who want to avoid accidental flyouts can increase delays (1.5s - 2.0s)
- **Accessibility**: Users with motor control challenges can set longer delays
- **Personal preference**: Users can fine-tune to their workflow

## Technical Details

### Implementation Pattern
All three delay settings follow the same pattern:
1. Store value in UserDefaults via `@AppStorage`
2. Components read the value directly from `@AppStorage`
3. Settings UI provides slider controls with real-time updates
4. Changes take effect immediately (no app restart required)

### Default Values
The defaults were chosen based on common UX patterns:
- **0.7s for clip previews**: Standard tooltip delay
- **0.5s for group flyouts**: Faster access to grouped items
- **1.0s for folders**: Longer delay for less frequently triggered actions

### Reset to Defaults
The "Reset to Defaults" button in settings will restore all three delays to their default values.

## Testing Recommendations

1. **Range testing**: Test extreme values (0.1s and 2.0s) for usability
2. **Immediate effect**: Verify changes apply without restart
3. **Persistence**: Verify settings persist across app launches
4. **UI consistency**: Check that all three delay types work as expected
5. **Accessibility**: Test with keyboard navigation and VoiceOver

## Future Enhancements

Potential improvements:
- Add preset profiles (Fast, Normal, Slow)
- Per-flyout enable/disable toggles
- Keyboard shortcuts to temporarily disable all flyouts
- Animation speed controls for flyout appearance

## Files Modified

1. `ClipboardManager.swift` - Added delay property definitions
2. `RecentClipsColumn.swift` - Updated ClipItemRow and HistoryGroupDisclosure
3. `FolderView.swift` - Updated folder hover behavior
4. `SettingsWindow.swift` - Added UI controls and settings views

---

**Date**: December 8, 2024
**Feature Type**: User Configuration Enhancement
**Impact**: Improved user experience and accessibility

# Accessibility Permission Detection Issue & Fix

**Date:** December 9, 2025  
**Issue:** Banner shows "Permission Required" even when permission is already granted  
**Root Cause:** macOS caches `AXIsProcessTrusted()` result  
**Status:** Fix needed

---

## Problem

### User Experience Issue:
1. User clicks "Enable" on banner
2. Dialog shows → user clicks "Open Settings"
3. System Settings opens showing **SimpleCP already has permission** (toggle is ON)
4. User returns to SimpleCP
5. **Banner still shows** "Permission Required"

### Technical Root Cause:
```swift
let trusted = AXIsProcessTrusted()
// ↑ Returns FALSE even when permission is ON
```

**Why this happens:**
- macOS caches the accessibility permission check
- The cache is only cleared when the app **restarts**
- OR when the permission is **changed** (toggled off then on)
- This is a macOS system behavior, not a bug in our code

---

## Solutions

### Solution 1: Add Restart App Button (Immediate Fix)

Update the banner to show a restart button when permission is detected as possibly granted:

```swift
// In AccessibilityStatusBanner.swift

if !permissionMonitor.isGranted && !permissionMonitor.isDismissed {
    HStack(spacing: 8) {
        // ... existing UI ...
        
        // NEW: Add restart app button
        Button("Restart App") {
            NSApp.terminate(nil)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .help("Restart to detect permission changes")
    }
}
```

### Solution 2: Add Manual "I've Enabled It" Button

Let users manually confirm they've enabled the permission:

```swift
Button("I've Enabled It") {
    // Dismiss the banner even though system check says no
    permissionMonitor.manuallyMarkAsGranted()
}
```

### Solution 3: Detect Permission Grant Externally (Advanced)

Use a distributed notification observer to detect when permissions change:

```swift
class AccessibilityPermissionMonitor: ObservableObject {
    init() {
        // Listen for accessibility permission changes
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(accessibilityChanged),
            name: NSNotification.Name("com.apple.accessibility.api"),
            object: nil
        )
    }
    
    @objc private func accessibilityChanged() {
        checkPermission()
    }
}
```

### Solution 4: Better User Guidance (What We Should Do)

Update the dialog to explicitly tell users to restart:

```swift
alert.informativeText = """
SimpleCP can automatically paste clips to your active application.

To enable this feature:

1. Click "Open Settings" below
2. Find "SimpleCP" in the list
3. Toggle the switch to enable
4. **Restart SimpleCP** for changes to take effect

This feature is optional. You can still copy clips normally without it.
"""
```

---

## Recommended Implementation

### Quick Fix (5 minutes):

1. Update `AccessibilityPermissionManager.swift` dialog to mention restart requirement
2. Add a "Dismiss" button to banner (we already have this)
3. Document the behavior

### Better Fix (15 minutes):

1. Add "Restart SimpleCP" button to banner
2. Add "I've Enabled It - Dismiss Banner" button
3. Make banner smarter about when to show

### Complete Fix (30 minutes):

1. Implement Solution 3 (distributed notifications)
2. Add automatic restart prompt after Settings closes
3. Better state management

---

## Implementation: Quick Fix

### Step 1: Update Dialog Text

File: `AccessibilityPermissionManager.swift`

```swift
func requestPermission(from window: NSWindow?, completion: @escaping (Bool) -> Void) {
    // ... existing code ...
    
    alert.informativeText = """
    SimpleCP can automatically paste clips to your active application.
    
    To enable this feature:
    
    1. Click "Open Settings" below
    2. Find "SimpleCP" in the list
    3. Toggle the switch to enable
    4. Restart SimpleCP (Quit and reopen)
    
    Note: macOS requires an app restart for permission changes to take effect.
    
    This feature is optional. You can still copy clips normally without it.
    """
}
```

### Step 2: Add Restart Button to Banner

File: `AccessibilityStatusBanner.swift`

```swift
HStack(spacing: 8) {
    Image(systemName: "exclamationmark.triangle.fill")
        .foregroundColor(.orange)
    
    VStack(alignment: .leading, spacing: 2) {
        Text("Accessibility Permission Required")
            .font(fontPrefs.interfaceFont(weight: .semibold))
        Text("Enable \"Paste Immediately\" feature")
            .font(.system(size: 11))
            .foregroundColor(.secondary)
    }
    
    Spacer()
    
    // NEW: Restart button
    Button("Restart App") {
        NSApplication.shared.terminate(nil)
    }
    .buttonStyle(.bordered)
    .controlSize(.small)
    .help("Restart SimpleCP to detect permission changes")
    
    Button("Enable") {
        AccessibilityPermissionManager.shared.requestPermission(from: NSApp.keyWindow) { _ in
            // After opening settings, suggest restart
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                suggestRestart()
            }
        }
    }
    .buttonStyle(.borderedProminent)
    .controlSize(.small)
    
    Button(action: {
        permissionMonitor.dismissBanner()
    }) {
        Image(systemName: "xmark")
    }
    .buttonStyle(.plain)
    .help("Dismiss (if you've already enabled)")
}

func suggestRestart() {
    let alert = NSAlert()
    alert.messageText = "Permission Enabled?"
    alert.informativeText = "If you've enabled Accessibility permission in System Settings, restart SimpleCP for changes to take effect."
    alert.addButton(withTitle: "Restart Now")
    alert.addButton(withTitle: "Later")
    
    if alert.runModal() == .alertFirstButtonReturn {
        NSApplication.shared.terminate(nil)
    }
}
```

### Step 3: Add Manual Dismissal

File: `AccessibilityPermissionMonitor.swift`

```swift
class AccessibilityPermissionMonitor: ObservableObject {
    // ... existing code ...
    
    func manuallyMarkAsGranted() {
        // User says they've enabled it, trust them
        isDismissed = true
        UserDefaults.standard.set(true, forKey: dismissedKey)
        print("ℹ️ User manually dismissed accessibility banner")
    }
}
```

---

## Why This Happens (Technical Details)

### macOS System Behavior:

1. **Security Design**: macOS caches accessibility checks for security
2. **Process-Based**: Each running process has its own cached state
3. **Update Mechanism**: Cache only updates when:
   - App restarts
   - Permission is toggled OFF then ON (system forces refresh)
   - System reboots (clears all caches)

### Code Behavior:

```swift
// First call (permission OFF)
AXIsProcessTrusted() // Returns false ✓

// User goes to Settings, enables permission
// ...

// Second call (permission NOW ON, but app still running)
AXIsProcessTrusted() // Returns false ✗ (cached!)

// After app restart
AXIsProcessTrusted() // Returns true ✓
```

### Why Apple Does This:

- **Performance**: Checking TCC (Transparency, Consent, and Control) database is expensive
- **Security**: Prevents frequent permission status probing
- **Stability**: Ensures consistent behavior during app lifecycle

---

## User Workarounds (Current)

Until we implement the fix, users can:

1. **Dismiss the banner** (click X) - it won't show again this session
2. **Restart SimpleCP** - Cmd+Q then reopen
3. **Toggle permission** - Turn OFF, then ON in System Settings (forces refresh)

---

## Testing the Fix

### Before Fix:
1. Disable accessibility permission
2. Launch SimpleCP
3. Banner shows ✓
4. Click "Enable" → opens Settings
5. Enable permission
6. Return to SimpleCP
7. **Banner still shows** ✗

### After Fix:
1. Same steps 1-6
2. Banner shows "Restart App" button ✓
3. Click "Restart App" → app quits and reopens
4. Banner gone ✓

---

## Priority

**High** - This is confusing for users and makes the feature seem broken

## Estimated Time

**Quick Fix**: 10 minutes
**Complete Fix**: 30 minutes

---

## Status

**Current**: Issue identified, solution designed  
**Next**: Implement quick fix (update dialog text + add restart button)

---

## Related Files

- `AccessibilityStatusBanner.swift` - Banner UI
- `AccessibilityPermissionMonitor.swift` - Permission checking
- `AccessibilityPermissionManager.swift` - Permission request dialog
- `PASTE_IMMEDIATELY_FIX.md` - Related paste functionality

---

**TL;DR:** macOS caches permission checks. App needs restart to detect changes. Solution: Add "Restart App" button to banner and update dialog to mention restart requirement.

# Accessibility Permissions Improvement Plan

**Priority:** High  
**Status:** In Progress  
**Date Created:** December 9, 2025

---

## Current State

### What Works
- ✅ `AccessibilityPermissionManager.swift` exists with good structure
- ✅ Permission checking is implemented
- ✅ Can open System Settings to Accessibility pane
- ✅ Paste functionality works when permissions granted

### Current Issues
1. **Inconsistent Permission Checking**: `RecentClipsColumn.swift` has its own implementation instead of using `AccessibilityPermissionManager`
2. **No Proactive Permission Request**: App doesn't prompt for permissions on first launch
3. **No Status Indicator**: Users don't know if permissions are granted or not
4. **No Settings Integration**: No way to check/request permissions from Settings window
5. **Poor User Guidance**: Alert text could be more helpful with step-by-step instructions
6. **No Permission Monitoring**: App doesn't detect when permissions are granted/revoked during runtime

---

## Problems to Solve

### 1. Duplicate Code
`RecentClipsColumn.swift` (line 225) has its own `pasteToActiveApp()` implementation that duplicates logic from `AccessibilityPermissionManager`.

### 2. Silent Failure Mode
Currently in `SimpleCPApp.swift`:
```swift
private func checkAccessibilityPermissionsSilent() {
    let trusted = AXIsProcessTrusted()
    // Only prints in DEBUG, user never knows
}
```

### 3. No Visual Feedback
Users can't see:
- Whether permissions are granted
- How to grant permissions
- What features require permissions

### 4. macOS Version Compatibility
The URL scheme for System Settings changed in macOS 13+:
- macOS 13+: `x-apple.systempreferences:`
- macOS 12 and earlier: Different scheme needed

---

## Solution Architecture

### Phase 1: Consolidate Permission Checking (30 min)

**Goal**: Remove duplicate code, use `AccessibilityPermissionManager` everywhere

#### Changes to `RecentClipsColumn.swift`

Replace the `pasteToActiveApp()` function with:

```swift
private func pasteToActiveApp() {
    AccessibilityPermissionManager.shared.pasteWithPermissionCheck(
        content: clipboardManager.currentClipboard,
        from: NSApp.keyWindow
    ) { success in
        if !success {
            print("⚠️ Paste failed: Permission not granted")
        }
    }
}
```

#### Also Update `HistoryGroupDisclosure` (line 467)

The `onPasteToActiveApp` closure is passed down but uses the same logic. Update to use the centralized manager.

---

### Phase 2: Add Permission Status Indicator (1 hour)

**Goal**: Show users the current permission state in the UI

#### Create New View: `AccessibilityStatusBanner.swift`

```swift
import SwiftUI
import ApplicationServices

struct AccessibilityStatusBanner: View {
    @StateObject private var permissionMonitor = AccessibilityPermissionMonitor.shared
    @Environment(\.fontPreferences) private var fontPrefs
    
    var body: some View {
        if !permissionMonitor.isGranted {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 14))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Accessibility Permission Required")
                        .font(fontPrefs.interfaceFont(weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Enable \"Paste Immediately\" feature")
                        .font(fontPrefs.interfaceFont())
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                }
                
                Spacer()
                
                Button("Enable") {
                    AccessibilityPermissionManager.shared.requestPermission(from: NSApp.keyWindow) { granted in
                        if granted {
                            permissionMonitor.checkPermission()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button(action: {
                    permissionMonitor.dismissBanner()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Color.orange.opacity(0.15))
            .cornerRadius(8)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
}

/// Monitors accessibility permission status and provides reactive updates
@MainActor
class AccessibilityPermissionMonitor: ObservableObject {
    static let shared = AccessibilityPermissionMonitor()
    
    @Published var isGranted: Bool = false
    @Published var isDismissed: Bool = false
    
    private var timer: Timer?
    
    private init() {
        checkPermission()
        startMonitoring()
    }
    
    func checkPermission() {
        isGranted = AXIsProcessTrusted()
    }
    
    func startMonitoring() {
        // Check every 2 seconds for permission changes
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkPermission()
        }
    }
    
    func dismissBanner() {
        isDismissed = true
        // Stop showing for this session
    }
    
    deinit {
        timer?.invalidate()
    }
}
```

#### Add to `ContentView.swift`

Add the banner above the main content:

```swift
VStack(spacing: 0) {
    // NEW: Permission status banner
    if !AccessibilityPermissionMonitor.shared.isDismissed {
        AccessibilityStatusBanner()
    }
    
    // Existing content...
    ControlBarView(...)
    // etc.
}
```

---

### Phase 3: Add Settings Section (1 hour)

**Goal**: Let users manage permissions from Settings window

#### Create New File: `PermissionsSettingsView.swift`

```swift
import SwiftUI
import ApplicationServices

struct PermissionsSettingsView: View {
    @StateObject private var permissionMonitor = AccessibilityPermissionMonitor.shared
    @Environment(\.fontPreferences) private var fontPrefs
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PERMISSIONS")
                .font(fontPrefs.interfaceFont(weight: .semibold))
            
            // Accessibility Permission
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Image(systemName: permissionMonitor.isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(permissionMonitor.isGranted ? .green : .red)
                                    .font(.system(size: 16))
                                
                                Text("Accessibility Access")
                                    .font(fontPrefs.interfaceFont(weight: .medium))
                            }
                            
                            Text(permissionMonitor.isGranted ? "Granted" : "Not Granted")
                                .font(fontPrefs.interfaceFont())
                                .foregroundColor(permissionMonitor.isGranted ? .green : .red)
                        }
                        
                        Spacer()
                        
                        if !permissionMonitor.isGranted {
                            Button("Grant Permission") {
                                AccessibilityPermissionManager.shared.requestPermission(from: nil) { _ in
                                    permissionMonitor.checkPermission()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button("Open Settings") {
                                AccessibilityPermissionManager.shared.openAccessibilitySettings()
                            }
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What This Enables:")
                            .font(fontPrefs.interfaceFont(weight: .medium))
                            .foregroundColor(.secondary)
                        
                        FeatureListItem(
                            icon: "command",
                            title: "Paste Immediately",
                            description: "Automatically paste clips to active app",
                            enabled: permissionMonitor.isGranted
                        )
                        
                        FeatureListItem(
                            icon: "keyboard",
                            title: "Keyboard Simulation",
                            description: "Simulate Cmd+V keypress programmatically",
                            enabled: permissionMonitor.isGranted
                        )
                    }
                    
                    Divider()
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How to Grant Permission:")
                            .font(fontPrefs.interfaceFont(weight: .medium))
                            .foregroundColor(.secondary)
                        
                        InstructionStep(number: 1, text: "Click \"Grant Permission\" above")
                        InstructionStep(number: 2, text: "System Settings will open to Accessibility")
                        InstructionStep(number: 3, text: "Find SimpleCP in the list")
                        InstructionStep(number: 4, text: "Toggle the switch to enable")
                        InstructionStep(number: 5, text: "Return to SimpleCP (no restart needed)")
                    }
                }
                .padding(12)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            permissionMonitor.checkPermission()
        }
    }
}

struct FeatureListItem: View {
    let icon: String
    let title: String
    let description: String
    let enabled: Bool
    @Environment(\.fontPreferences) private var fontPrefs
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(enabled ? .green : .secondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(fontPrefs.interfaceFont(weight: .medium))
                Text(description)
                    .font(fontPrefs.interfaceFont())
                    .foregroundColor(.secondary)
                    .font(.system(size: 11))
            }
            
            Spacer()
            
            Image(systemName: enabled ? "checkmark.circle.fill" : "circle")
                .foregroundColor(enabled ? .green : .secondary)
        }
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String
    @Environment(\.fontPreferences) private var fontPrefs
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .font(fontPrefs.interfaceFont(weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 20, alignment: .trailing)
            
            Text(text)
                .font(fontPrefs.interfaceFont())
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

#Preview {
    PermissionsSettingsView()
        .frame(width: 500, height: 400)
}
```

#### Update `SettingsWindow.swift`

Add a new tab for Permissions:

```swift
TabView(selection: $selectedTab) {
    GeneralSettingsView(...)
        .tabItem {
            Label("General", systemImage: "gearshape")
        }
        .tag(0)
    
    // NEW: Permissions tab
    PermissionsSettingsView()
        .tabItem {
            Label("Permissions", systemImage: "lock.shield")
        }
        .tag(1)
    
    AppearanceSettingsView(...)
        .tabItem {
            Label("Appearance", systemImage: "paintbrush")
        }
        .tag(2)
    
    // etc...
}
```

---

### Phase 4: Improve Permission Request Dialog (30 min)

**Goal**: Make the permission request more informative and actionable

#### Update `AccessibilityPermissionManager.swift`

Replace the `requestPermission` method:

```swift
/// Request Accessibility permission with an improved dialog
func requestPermission(from window: NSWindow?, completion: @escaping (Bool) -> Void) {
    // First check if already granted
    if checkPermission(promptIfNeeded: false) {
        completion(true)
        return
    }
    
    // Show improved alert
    DispatchQueue.main.async {
        let alert = NSAlert()
        alert.messageText = "Enable \"Paste Immediately\" Feature"
        alert.informativeText = """
        SimpleCP can automatically paste clips to your active application.
        
        To enable this feature:
        
        1. Click "Open Settings" below
        2. Find "SimpleCP" in the list
        3. Toggle the switch to enable
        4. Return to SimpleCP (no restart needed)
        
        This feature is optional. You can still copy clips normally without it.
        """
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Not Now")
        alert.alertStyle = .informational
        alert.icon = NSImage(systemSymbolName: "hand.tap.fill", accessibilityDescription: "Permission")
        
        let handler: (NSApplication.ModalResponse) -> Void = { response in
            if response == .alertFirstButtonReturn {
                self.openAccessibilitySettings()
                // Poll for permission grant
                self.pollForPermission(attempts: 30, interval: 1.0) { granted in
                    completion(granted)
                }
            } else {
                completion(false)
            }
        }
        
        if let window = window {
            alert.beginSheetModal(for: window, completionHandler: handler)
        } else {
            let response = alert.runModal()
            handler(response)
        }
    }
}

/// Poll for permission grant (useful after opening Settings)
private func pollForPermission(attempts: Int, interval: TimeInterval, completion: @escaping (Bool) -> Void) {
    var remainingAttempts = attempts
    
    let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
        if self.checkPermission(promptIfNeeded: false) {
            timer.invalidate()
            completion(true)
        } else {
            remainingAttempts -= 1
            if remainingAttempts <= 0 {
                timer.invalidate()
                completion(false)
            }
        }
    }
    
    RunLoop.main.add(timer, forMode: .common)
}
```

---

### Phase 5: First-Launch Experience (45 min)

**Goal**: Proactively request permissions on first launch

#### Create `FirstLaunchManager.swift`

```swift
import Foundation
import AppKit

@MainActor
class FirstLaunchManager: ObservableObject {
    static let shared = FirstLaunchManager()
    
    @Published var isFirstLaunch: Bool = false
    
    private let firstLaunchKey = "hasLaunchedBefore"
    private let permissionRequestedKey = "hasRequestedAccessibilityPermission"
    
    private init() {
        checkFirstLaunch()
    }
    
    func checkFirstLaunch() {
        isFirstLaunch = !UserDefaults.standard.bool(forKey: firstLaunchKey)
    }
    
    func markAsLaunched() {
        UserDefaults.standard.set(true, forKey: firstLaunchKey)
        isFirstLaunch = false
    }
    
    func shouldRequestPermission() -> Bool {
        // Only request if:
        // 1. First launch OR
        // 2. Never requested before
        let neverRequested = !UserDefaults.standard.bool(forKey: permissionRequestedKey)
        return isFirstLaunch || neverRequested
    }
    
    func markPermissionRequested() {
        UserDefaults.standard.set(true, forKey: permissionRequestedKey)
    }
    
    /// Show welcome screen with permission request
    func showWelcomeIfNeeded() {
        guard shouldRequestPermission() else { return }
        
        // Show after a short delay to let the app settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showWelcomeScreen()
        }
    }
    
    private func showWelcomeScreen() {
        let alert = NSAlert()
        alert.messageText = "Welcome to SimpleCP!"
        alert.informativeText = """
        SimpleCP is a powerful clipboard manager for macOS.
        
        To get the most out of SimpleCP, we recommend enabling the "Paste Immediately" feature, which requires Accessibility permission.
        
        You can enable this now, or skip and enable it later in Settings.
        """
        alert.addButton(withTitle: "Enable Now")
        alert.addButton(withTitle: "Skip")
        alert.alertStyle = .informational
        alert.icon = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Welcome")
        
        let response = alert.runModal()
        markPermissionRequested()
        markAsLaunched()
        
        if response == .alertFirstButtonReturn {
            AccessibilityPermissionManager.shared.requestPermission(from: nil) { _ in
                // Permission flow handled by manager
            }
        }
    }
}
```

#### Update `SimpleCPApp.swift`

```swift
init() {
    // Check accessibility permissions silently (no prompt)
    checkAccessibilityPermissionsSilent()
    
    // NEW: Show welcome screen on first launch
    Task { @MainActor in
        FirstLaunchManager.shared.showWelcomeIfNeeded()
    }
}
```

---

### Phase 6: macOS Version Compatibility (15 min)

**Goal**: Support both old and new System Settings URL schemes

#### Update `AccessibilityPermissionManager.swift`

```swift
/// Open System Settings to Accessibility preferences (macOS version-aware)
func openAccessibilitySettings() {
    if #available(macOS 13, *) {
        // macOS 13+ (Ventura and later) - uses new Settings app
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    } else {
        // macOS 12 and earlier - uses System Preferences
        let prefpaneUrl = URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane")
        NSWorkspace.shared.open(prefpaneUrl)
    }
}
```

---

## Implementation Timeline

| Phase | Task | Time | Priority |
|-------|------|------|----------|
| 1 | Consolidate permission checking | 30 min | High |
| 2 | Add permission status banner | 1 hour | High |
| 3 | Add settings section | 1 hour | Medium |
| 4 | Improve request dialog | 30 min | Medium |
| 5 | First-launch experience | 45 min | Low |
| 6 | macOS version compatibility | 15 min | Medium |

**Total Estimated Time:** 4 hours

---

## Testing Checklist

### Manual Tests

- [ ] **Grant permission**: Fresh install → grant permission → test paste immediately
- [ ] **Deny permission**: Fresh install → deny → verify graceful handling
- [ ] **Revoke permission**: Grant → use feature → revoke in Settings → verify detection
- [ ] **Re-grant permission**: Revoke → re-grant → verify auto-detection (no restart)
- [ ] **Banner display**: Verify banner shows when permission not granted
- [ ] **Banner dismiss**: Dismiss banner → verify it stays dismissed for session
- [ ] **Settings tab**: Open Settings → Permissions tab → verify status correct
- [ ] **Settings button**: Click "Grant Permission" → Settings opens → grant → verify status updates
- [ ] **First launch**: Delete UserDefaults → launch → verify welcome screen
- [ ] **Skip first launch**: Welcome → Skip → verify doesn't show again
- [ ] **macOS 13+**: Test Settings URL on Ventura/Sonoma
- [ ] **macOS 12**: Test old System Preferences path

### Edge Cases

- [ ] App already has permission (don't show banners/prompts)
- [ ] Permission requested but user closes Settings without granting
- [ ] Permission granted while app running in background
- [ ] Multiple windows open when requesting permission
- [ ] Paste immediately called rapidly (queue/debounce)

### Regression Tests

- [ ] Existing copy/paste functionality unaffected
- [ ] Clipboard history still works without permissions
- [ ] Snippets still work without permissions
- [ ] Search/filter still works
- [ ] Settings window still opens correctly

---

## Files to Create

1. `AccessibilityStatusBanner.swift` - Permission status banner for main UI
2. `PermissionsSettingsView.swift` - Settings tab for permissions
3. `FirstLaunchManager.swift` - First-launch welcome flow
4. `ACCESSIBILITY_PERMISSIONS_IMPROVEMENT.md` - This document

## Files to Modify

1. `RecentClipsColumn.swift` - Use centralized permission manager
2. `AccessibilityPermissionManager.swift` - Improve dialog and add polling
3. `ContentView.swift` - Add permission banner
4. `SettingsWindow.swift` - Add Permissions tab
5. `SimpleCPApp.swift` - Add first-launch check

---

## Success Criteria

✅ No duplicate permission checking code  
✅ Users can see permission status at a glance  
✅ Clear instructions on how to grant permissions  
✅ Settings has dedicated permissions section  
✅ First-launch prompts for permissions (optional)  
✅ Works on macOS 12, 13, 14+  
✅ Auto-detects when permissions granted/revoked  
✅ Graceful degradation when permissions denied  

---

## Future Enhancements

- **Notification on permission grant**: Toast/banner when permission detected
- **Permission analytics**: Track permission grant rate
- **Alternative paste methods**: For users who won't grant permissions (e.g., show notification to paste manually)
- **Keyboard shortcut reminder**: Show Cmd+V hint when permissions denied
- **Video tutorial**: Link to video showing how to grant permissions

---

**Status:** Ready for implementation  
**Priority:** High  
**Estimated Effort:** 4 hours  
**Dependencies:** None

---

**Last Updated:** December 9, 2025  
**Document Version:** 1.0

//
//  RecentClipsColumn+PasteActions.swift
//  SimpleCP
//
//  Paste action utilities using Accessibility API and CGEvents
//

import SwiftUI
import ApplicationServices
import Carbon.HIToolbox

// MARK: - Paste Action Helpers

struct PasteActionHelper {
    static func executePaste(targetPID: pid_t?) {
        if let pid = targetPID, executePasteViaMenu(pid: pid) {
            print("⌨️ Executed paste via Menu API")
            return
        }
        print("⚠️ Menu paste failed, trying CGEvents...")
        executePasteViaCGEvents(targetPID: targetPID)
    }

    static func executePasteViaMenu(pid: pid_t) -> Bool {
        let appElement = AXUIElementCreateApplication(pid)

        var menuBar: CFTypeRef?
        let menuBarResult = AXUIElementCopyAttributeValue(appElement, kAXMenuBarAttribute as CFString, &menuBar)

        guard menuBarResult == .success, let menuBarElement = menuBar else {
            print("❌ Could not get menu bar (AX error: \(menuBarResult.rawValue))")
            return false
        }

        var menuBarItems: CFTypeRef?
        guard AXUIElementCopyAttributeValue(menuBarElement as! AXUIElement, kAXChildrenAttribute as CFString, &menuBarItems) == .success,
              let items = menuBarItems as? [AXUIElement] else {
            print("❌ Could not get menu bar items")
            return false
        }

        for item in items {
            var title: CFTypeRef?
            if AXUIElementCopyAttributeValue(item, kAXTitleAttribute as CFString, &title) == .success,
               let menuTitle = title as? String, menuTitle == "Edit" {

                var editMenu: CFTypeRef?
                guard AXUIElementCopyAttributeValue(item, kAXChildrenAttribute as CFString, &editMenu) == .success,
                      let editMenuItems = (editMenu as? [AXUIElement])?.first else {
                    print("❌ Could not get Edit menu")
                    return false
                }

                var editChildren: CFTypeRef?
                guard AXUIElementCopyAttributeValue(editMenuItems, kAXChildrenAttribute as CFString, &editChildren) == .success,
                      let editItems = editChildren as? [AXUIElement] else {
                    print("❌ Could not get Edit menu items")
                    return false
                }

                for editItem in editItems {
                    var itemTitle: CFTypeRef?
                    if AXUIElementCopyAttributeValue(editItem, kAXTitleAttribute as CFString, &itemTitle) == .success,
                       let name = itemTitle as? String, name == "Paste" {
                        let pressResult = AXUIElementPerformAction(editItem, kAXPressAction as CFString)
                        if pressResult == .success {
                            print("✅ Clicked Edit > Paste menu")
                            return true
                        } else {
                            print("❌ Failed to click Paste (AX error: \(pressResult.rawValue))")
                            return false
                        }
                    }
                }
                print("❌ Paste item not found in Edit menu")
                return false
            }
        }
        print("❌ Edit menu not found")
        return false
    }

    static func executePasteViaCGEvents(targetPID: pid_t?) {
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            print("❌ Failed to create CGEventSource")
            showPermissionDeniedAlert()
            return
        }

        let keyCode: CGKeyCode = 0x09 // V key

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            print("❌ Failed to create CGEvents")
            showPermissionDeniedAlert()
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        if let pid = targetPID {
            print("🎯 Posting CGEvents to PID: \(pid)")
            keyDown.postToPid(pid)
            usleep(10000)
            keyUp.postToPid(pid)
        } else {
            print("📤 Posting CGEvents globally")
            keyDown.post(tap: .cghidEventTap)
            usleep(10000)
            keyUp.post(tap: .cghidEventTap)
        }

        print("⌨️ Executed paste via CGEvents (⌘V)")
    }

    static func showPermissionDeniedAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = """
            The "Paste Immediately" feature requires Accessibility permission to simulate keyboard input.

            To enable this feature:

            1. Click "Open System Settings" below
            2. Find "SimpleCP" in the Accessibility list
            3. Toggle the switch ON
            4. **Quit and restart SimpleCP** (⌘Q then reopen)

            Note: This is optional. You can still copy clips normally without this permission.
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Not Now")

            if let icon = NSImage(systemSymbolName: "hand.tap.fill", accessibilityDescription: "Permission") {
                alert.icon = icon
            }

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                AccessibilityPermissionManager.shared.openAccessibilitySettings()
            }
        }
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe range: Range<Index>) -> ArraySlice<Element>? {
        if range.lowerBound >= 0 && range.upperBound <= count {
            return self[range]
        }
        return nil
    }
}

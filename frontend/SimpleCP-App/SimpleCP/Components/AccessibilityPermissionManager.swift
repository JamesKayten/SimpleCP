//
//  AccessibilityPermissionManager.swift
//  SimpleCP
//
//  Manages Accessibility permission checks and requests
//

import Foundation
import AppKit
import ApplicationServices

class AccessibilityPermissionManager {
    static let shared = AccessibilityPermissionManager()
    
    private init() {}
    
    /// Check if Accessibility permission is granted
    /// This will prompt the user if not already prompted
    func checkPermission(promptIfNeeded: Bool = true) -> Bool {
        if promptIfNeeded {
            // This will show the system prompt if permission hasn't been requested yet
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        } else {
            // Just check without prompting
            return AXIsProcessTrusted()
        }
    }
    
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
            4. **Quit and restart SimpleCP** (Cmd+Q)
            
            Note: macOS requires a restart for this change to take effect.
            
            This feature is optional. You can still copy clips normally without it.
            """
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "Not Now")
            alert.alertStyle = .informational
            if let icon = NSImage(systemSymbolName: "hand.tap.fill", accessibilityDescription: "Permission") {
                alert.icon = icon
            }
            
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
                print("✅ Accessibility permission detected!")
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
    
    /// Execute paste action with permission check
    func pasteWithPermissionCheck(content: String, from window: NSWindow?, completion: @escaping (Bool) -> Void) {
        // Check permission first
        if checkPermission(promptIfNeeded: false) {
            // Permission granted, copy content and execute paste
            copyToClipboard(content)
            executePaste()
            completion(true)
        } else {
            // Request permission
            requestPermission(from: window) { granted in
                if granted {
                    self.copyToClipboard(content)
                    self.executePaste()
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
    
    /// Copy content to clipboard (synchronous, main thread)
    private func copyToClipboard(_ content: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
        print("📋 Copied to clipboard: \(content.prefix(50))...")
    }
    
    /// Execute the actual paste command (Cmd+V)
    private func executePaste() {
        // Small delay to let the clipboard settle and focus to shift
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let source = CGEventSource(stateID: .hidSystemState)
            
            // Key down event for Cmd+V
            let keyVDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
            keyVDown?.flags = .maskCommand
            
            // Key up event for Cmd+V
            let keyVUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
            keyVUp?.flags = .maskCommand
            
            // Post the events
            keyVDown?.post(tap: .cghidEventTap)
            keyVUp?.post(tap: .cghidEventTap)
            
            print("⌨️ Simulated Cmd+V keypress")
        }
    }
}

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
    
    /// Request Accessibility permission with a custom dialog
    func requestPermission(from window: NSWindow?, completion: @escaping (Bool) -> Void) {
        // First check if already granted
        if checkPermission(promptIfNeeded: false) {
            completion(true)
            return
        }
        
        // Show custom alert
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = """
            SimpleCP needs Accessibility permissions to paste content automatically.
            
            After clicking 'Open Settings', find SimpleCP in the list and enable it.
            
            Note: You may need to restart SimpleCP after granting permission.
            """
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "Cancel")
            alert.alertStyle = .informational
            
            let handler: (NSApplication.ModalResponse) -> Void = { response in
                if response == .alertFirstButtonReturn {
                    self.openAccessibilitySettings()
                    // Give user time to grant permission
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        completion(self.checkPermission(promptIfNeeded: false))
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
    
    /// Open System Settings to Accessibility preferences
    func openAccessibilitySettings() {
        // macOS 13+ (Ventura and later)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Execute paste action with permission check
    func pasteWithPermissionCheck(content: String, from window: NSWindow?, completion: @escaping (Bool) -> Void) {
        // Check permission first
        if checkPermission(promptIfNeeded: false) {
            // Permission granted, execute paste
            executePaste()
            completion(true)
        } else {
            // Request permission
            requestPermission(from: window) { granted in
                if granted {
                    self.executePaste()
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
    
    /// Execute the actual paste command (Cmd+V)
    private func executePaste() {
        // Small delay to let the app switch focus
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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
        }
    }
}

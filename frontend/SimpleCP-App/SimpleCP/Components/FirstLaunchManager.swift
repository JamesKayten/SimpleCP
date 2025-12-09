//
//  FirstLaunchManager.swift
//  SimpleCP
//
//  Manages first-launch experience and permission requests
//

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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
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
        
        if let icon = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Welcome") {
            alert.icon = icon
        }
        
        let response = alert.runModal()
        markPermissionRequested()
        markAsLaunched()
        
        if response == .alertFirstButtonReturn {
            AccessibilityPermissionManager.shared.requestPermission(from: nil) { granted in
                if granted {
                    print("✅ User granted accessibility permission on first launch")
                } else {
                    print("ℹ️ User postponed granting accessibility permission")
                }
            }
        } else {
            print("ℹ️ User skipped first-launch permission request")
        }
    }
}

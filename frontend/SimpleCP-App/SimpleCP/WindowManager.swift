//
//  WindowManager.swift
//  SimpleCP
//
//  Manages window opening from anywhere in the app
//

import SwiftUI
import AppKit

// Helper class to manage window opening from anywhere
class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    // Store a reference to the environment's openSettings action
    static var openSettingsAction: (() -> Void)?
    
    @MainActor func openSettingsWindow() {
        // DON'T hide the main window - we want to see it resize in real-time
        
        #if DEBUG
        print("🔧 Opening Settings window (keeping main window visible)")
        #endif
        
        // Temporarily ensure app is in regular mode to show settings window
        let currentPolicy = NSApp.activationPolicy()
        let wasAccessory = (currentPolicy == .accessory)
        
        if wasAccessory {
            NSApp.setActivationPolicy(.regular)
        }
        
        // Open settings
        if let openSettings = WindowManager.openSettingsAction {
            openSettings()
        } else {
            #if DEBUG
            print("⚠️ WindowManager.openSettingsAction not set")
            #endif
        }
        
        // Restore accessory mode after a delay if needed
        if wasAccessory {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Only restore if user still has "Show in Dock" disabled
                let showInDock = UserDefaults.standard.bool(forKey: "showInDock")
                if !showInDock {
                    NSApp.setActivationPolicy(.accessory)
                }
            }
        }
    }
}

// Add shared instances to ClipboardManager and BackendService
extension ClipboardManager {
    private static var _shared: ClipboardManager?
    
    static var shared: ClipboardManager {
        guard let instance = _shared else {
            fatalError("ClipboardManager.shared accessed before makeShared() was called")
        }
        return instance
    }
    
    func makeShared() {
        ClipboardManager._shared = self
    }
}

extension BackendService {
    private static var _shared: BackendService?
    
    static var shared: BackendService {
        guard let instance = _shared else {
            fatalError("BackendService.shared accessed before makeShared() was called")
        }
        return instance
    }
    
    func makeShared() {
        BackendService._shared = self
    }
}

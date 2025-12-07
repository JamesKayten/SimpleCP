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
    
    // Store a reference to the environment's openWindow action
    static var openWindowAction: ((String) -> Void)?
    
    @MainActor func openSettingsWindow() {
        // Activate the app first
        NSApp.activate(ignoringOtherApps: true)
        
        // Find existing settings window and bring it to front
        if let settingsWindow = NSApp.windows.first(where: { $0.title == "Settings" }) {
            settingsWindow.makeKeyAndOrderFront(nil)
            settingsWindow.center()
            return
        }
        
        // If no window exists, try to open it via the stored action
        if let openWindow = WindowManager.openWindowAction {
            openWindow("settings")
        } else {
            // Fallback: manually create the settings window
            let settingsView = SettingsWindow()
                .environmentObject(ClipboardManager.shared)
                .environmentObject(BackendService.shared)
            
            let hostingController = NSHostingController(rootView: settingsView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = "Settings"
            window.setContentSize(NSSize(width: 500, height: 400))
            window.center()
            window.makeKeyAndOrderFront(nil)
            window.level = .floating
        }
    }
}

// Add shared instances to ClipboardManager and BackendService
extension ClipboardManager {
    static var shared: ClipboardManager {
        // This will be set by the App
        return _shared ?? ClipboardManager()
    }
    private static weak var _shared: ClipboardManager?
    
    func makeShared() {
        ClipboardManager._shared = self
    }
}

extension BackendService {
    static var shared: BackendService {
        // This will be set by the App
        return _shared ?? BackendService()
    }
    private static weak var _shared: BackendService?
    
    func makeShared() {
        BackendService._shared = self
    }
}

//
//  AppDelegate.swift
//  SimpleCP
//
//  Handles application lifecycle events
//

import SwiftUI
import os.log

class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "com.simplecp.app", category: "lifecycle")

    // Shared reference to backend service for cleanup
    static weak var sharedBackendService: BackendService?

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("🚀 Application finished launching")

        // Check user preference for showing in Dock (default to true for keyboard input support)
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "showInDock") == nil {
            // First launch - default to showing in Dock
            defaults.set(true, forKey: "showInDock")
        }
        let showInDock = defaults.bool(forKey: "showInDock")

        // Set activation policy based on user preference
        // .regular = shows in Dock, enables proper keyboard input
        // .accessory = menu bar only, but keyboard input may not work in dialogs
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)

        logger.info("Activation policy: \(showInDock ? "regular (show in Dock)" : "accessory (menu bar only)")")

        // Menu bar content will be set up by the App's view hierarchy
        // Backend will be started by BackendService init with proper exponential backoff
        // Window size is managed solely by MenuBarManager
    }

    func applicationWillTerminate(_ notification: Notification) {
        logger.info("🛑 Application will terminate - cleaning up backend...")

        // Stop the backend process
        if let backendService = AppDelegate.sharedBackendService {
            backendService.stopBackend()

            // Give it a moment to clean up
            Thread.sleep(forTimeInterval: 0.5)
        }

        logger.info("✅ Cleanup complete")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // For menu bar apps, don't terminate when windows close
        return false
    }
}

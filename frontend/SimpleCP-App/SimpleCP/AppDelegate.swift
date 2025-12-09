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
    
    // Observe window opacity changes
    private var windowOpacityObserver: NSObjectProtocol?
    
    // Track last applied opacity to prevent redundant updates
    private var lastAppliedOpacity: Double = 0.0

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("🚀 Application finished launching")
        
        // Set activation policy based on user preference
        applyActivationPolicy()
        
        // Menu bar content will be set up by the App's view hierarchy
        // Backend will be started by BackendService init with proper exponential backoff
        
        // Observe window opacity changes
        setupWindowOpacityObserver()
    }
    
    // MARK: - Activation Policy Management
    
    private func applyActivationPolicy() {
        let defaults = UserDefaults.standard
        
        // Set default on first launch
        if defaults.object(forKey: "showInDock") == nil {
            defaults.set(true, forKey: "showInDock")
        }
        
        let showInDock = defaults.bool(forKey: "showInDock")
        
        // .regular = shows in Dock, enables proper keyboard input
        // .accessory = menu bar only, but keyboard input may not work in dialogs
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)
        
        logger.info("Activation policy: \(showInDock ? "regular (show in Dock)" : "accessory (menu bar only)")")
    }
    
    // MARK: - Window Opacity Management
    
    private func setupWindowOpacityObserver() {
        windowOpacityObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handlePreferenceChange()
        }
        
        // Apply initial opacity after a slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.applyWindowOpacity()
        }
    }
    
    private func handlePreferenceChange() {
        // Check if activation policy changed
        let currentPolicy = NSApp.activationPolicy()
        let showInDock = UserDefaults.standard.bool(forKey: "showInDock")
        let expectedPolicy: NSApplication.ActivationPolicy = showInDock ? .regular : .accessory
        
        if currentPolicy != expectedPolicy {
            applyActivationPolicy()
        }
        
        // Handle opacity changes
        applyWindowOpacity()
    }
    
    private func applyWindowOpacity() {
        let opacity = UserDefaults.standard.double(forKey: "windowOpacity")
        let alphaValue = opacity > 0 ? opacity : 0.95 // Default to 0.95 if not set
        
        // Only apply if value has actually changed
        guard abs(lastAppliedOpacity - alphaValue) > 0.001 else {
            return
        }
        
        lastAppliedOpacity = alphaValue
        logger.info("🎨 Applying window opacity: \(Int(alphaValue * 100))%")
        
        // The opacity will be applied by MenuBarManager
        MenuBarManager.shared.updatePopoverOpacity(alphaValue)
    }

    func applicationWillTerminate(_ notification: Notification) {
        logger.info("🛑 Application will terminate - cleaning up backend...")

        // Remove observer
        if let observer = windowOpacityObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        // Stop the backend process
        if let backendService = AppDelegate.sharedBackendService {
            backendService.cleanup()

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

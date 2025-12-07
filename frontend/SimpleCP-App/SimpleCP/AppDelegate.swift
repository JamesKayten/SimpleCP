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
    
    // Observe window size changes
    private var windowSizeObserver: NSObjectProtocol?
    private var windowOpacityObserver: NSObjectProtocol?

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
        // No need for additional delays here
        
        // Observe window size preference changes
        setupWindowSizeObserver()
        
        // Observe window opacity changes
        setupWindowOpacityObserver()
    }
    
    // MARK: - Window Opacity Management
    
    private func setupWindowOpacityObserver() {
        windowOpacityObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.applyWindowOpacity()
        }
        
        // Apply initial opacity after a slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.applyWindowOpacity()
        }
    }
    
    // MARK: - Window Size Management
    
    private func setupWindowSizeObserver() {
        windowSizeObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.applyWindowSize()
        }
        
        // Apply initial size
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.applyWindowSize()
        }
    }
    
    private func applyWindowSize() {
        let windowSize = UserDefaults.standard.string(forKey: "windowSize") ?? "normal"
        let dimensions = windowDimensions(for: windowSize)
        
        // Find the MenuBarExtra window (it typically doesn't have a title)
        if let window = NSApp.windows.first(where: { window in
            // MenuBarExtra windows are usually NSPanel instances without titles
            return window is NSPanel && (window.title.isEmpty || window.title == "")
        }) {
            let currentFrame = window.frame
            let newFrame = NSRect(
                x: currentFrame.origin.x,
                y: currentFrame.origin.y + currentFrame.height - dimensions.height,
                width: dimensions.width,
                height: dimensions.height
            )
            
            logger.info("🔵 Applying window size: \(windowSize) (\(dimensions.width)x\(dimensions.height))")
            window.setFrame(newFrame, display: true, animate: true)
        }
    }
    
    private func applyWindowOpacity() {
        let opacity = UserDefaults.standard.double(forKey: "windowOpacity")
        let alphaValue = opacity > 0 ? opacity : 0.9 // Default to 0.9 if not set
        
        logger.info("🎨 Opacity preference changed to: \(Int(alphaValue * 100))%")
        
        // The opacity will be applied by MenuBarManager when popover is shown
        // and by the settings view when it changes
    }
    
    private func windowDimensions(for size: String) -> (width: CGFloat, height: CGFloat) {
        switch size {
        case "compact":
            return (400, 500)  // Portrait: taller than wide
        case "normal":
            return (450, 600)  // Portrait: taller than wide
        case "large":
            return (550, 750)  // Portrait: taller than wide
        default:
            return (450, 600)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        logger.info("🛑 Application will terminate - cleaning up backend...")

        // Remove observers
        if let observer = windowSizeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = windowOpacityObserver {
            NotificationCenter.default.removeObserver(observer)
        }

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

//
//  MenuBarManager.swift
//  SimpleCP
//
//  Created by Smallfavor on 12/5/25.
//

import Foundation
import SwiftUI
import AppKit

// Custom NSPanel that can accept keyboard input
class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}

class MenuBarManager: NSObject {
    static let shared = MenuBarManager()
    
    private var statusItem: NSStatusItem?
    var menuBarWindow: NSPanel?  // Made internal for WindowManager access
    var contentView: AnyView?
    private var eventMonitor: Any?  // Monitor for clicks outside the window
    
    override init() {
        super.init()
        setupStatusItem()
    }
    
    deinit {
        stopMonitoringClicksOutside()
    }
    
    // MARK: - Window Dimensions
    
    private var currentWindowDimensions: (width: CGFloat, height: CGFloat) {
        let width = UserDefaults.standard.integer(forKey: "windowWidth")
        let height = UserDefaults.standard.integer(forKey: "windowHeight")
        return (
            width: CGFloat(width > 0 ? width : 400),
            height: CGFloat(height > 0 ? height : 450)
        )
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }
        
        button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "SimpleCP")
        button.imagePosition = .imageLeading
        button.action = #selector(statusItemClicked(_:))
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
    
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePanel()
        }
    }
    
    private func togglePanel() {
        // Check if window exists AND is visible
        if let window = menuBarWindow, window.isVisible {
            window.orderOut(nil)
            stopMonitoringClicksOutside()
        } else {
            showPanel()
        }
    }
    
    // MARK: - Click Outside Detection
    
    private func startMonitoringClicksOutside() {
        // Remove existing monitor if any
        stopMonitoringClicksOutside()
        
        // Monitor left and right mouse clicks globally
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self,
                  let window = self.menuBarWindow,
                  window.isVisible else { return }
            
            // Get the click location in screen coordinates
            let clickLocation = NSEvent.mouseLocation
            
            // Check if click is outside the window frame
            if !window.frame.contains(clickLocation) {
                // Also check if click is not on the status item button
                if let button = self.statusItem?.button,
                   let buttonWindow = button.window {
                    let buttonFrame = button.convert(button.bounds, to: nil)
                    let screenButtonFrame = buttonWindow.convertToScreen(buttonFrame)
                    
                    // If click is not on the button either, close the window
                    if !screenButtonFrame.contains(clickLocation) {
                        window.orderOut(nil)
                        self.stopMonitoringClicksOutside()
                    }
                }
            }
        }
    }
    
    private func stopMonitoringClicksOutside() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    private func showPanel() {
        guard let button = statusItem?.button else { return }
        
        // Create window if it doesn't exist
        if menuBarWindow == nil {
            let windowDimensions = currentWindowDimensions
            
            #if DEBUG
            print("📐 Creating new menubar window with dimensions: \(windowDimensions.width) x \(windowDimensions.height)")
            #endif
            
            let panel = KeyablePanel(
                contentRect: NSRect(x: 0, y: 0, width: windowDimensions.width, height: windowDimensions.height),
                styleMask: [.borderless],  // Removed .nonactivatingPanel to allow keyboard input
                backing: .buffered,
                defer: false
            )
            
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.isFloatingPanel = true
            panel.hidesOnDeactivate = false  // Keep visible when clicking elsewhere
            panel.hasShadow = true
            
            // Set size constraints to prevent SwiftUI from resizing
            panel.minSize = NSSize(width: windowDimensions.width, height: windowDimensions.height)
            panel.maxSize = NSSize(width: windowDimensions.width, height: windowDimensions.height)
            
            // Apply corner radius
            panel.contentView?.wantsLayer = true
            panel.contentView?.layer?.cornerRadius = 12
            panel.contentView?.layer?.masksToBounds = true
            
            if let contentView = contentView {
                let hostingView = NSHostingController(rootView: contentView)
                // Prevent SwiftUI from controlling the size
                hostingView.sizingOptions = []
                panel.contentViewController = hostingView
            }
            
            menuBarWindow = panel
            
            // Position window below menu bar icon BEFORE showing it
            if let buttonWindow = button.window {
                let buttonFrame = button.convert(button.bounds, to: nil)
                let screenFrame = buttonWindow.convertToScreen(buttonFrame)
                
                let xPos = screenFrame.midX - (windowDimensions.width / 2)
                let yPos = screenFrame.minY - windowDimensions.height - 8
                
                panel.setFrame(NSRect(x: xPos, y: yPos, width: windowDimensions.width, height: windowDimensions.height), display: false)
            }
            
            // Apply appearance settings once after window is fully configured
            applyOpacityAndAppearance()
            
            // Show the window and make it key so it can accept keyboard input
            panel.orderFront(nil)
            panel.makeKey()
            
            // Start monitoring for clicks outside the window
            startMonitoringClicksOutside()
        } else {
            // Window already exists, just show it
            // No need to reposition or reconfigure
            menuBarWindow?.orderFront(nil)
            menuBarWindow?.makeKey()
            
            // Ensure event monitor is running
            startMonitoringClicksOutside()
        }
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func applyOpacityAndAppearance() {
        guard let window = menuBarWindow else { return }
        
        let opacity = UserDefaults.standard.double(forKey: "windowOpacity")
        let alphaValue = opacity > 0 ? opacity : 0.95
        
        // Only update if the value has actually changed
        let currentAlpha = window.alphaValue
        if abs(currentAlpha - alphaValue) > 0.001 { // Use epsilon for floating point comparison
            #if DEBUG
            print("🎨 Applying window opacity: \(Int(alphaValue * 100))%")
            #endif
            
            window.alphaValue = alphaValue
            window.isOpaque = false
            window.backgroundColor = .clear
        }
        
        let theme = UserDefaults.standard.string(forKey: "theme") ?? "auto"
        let targetAppearance: NSAppearance?
        
        switch theme.lowercased() {
        case "light":
            targetAppearance = NSAppearance(named: .aqua)
        case "dark":
            targetAppearance = NSAppearance(named: .darkAqua)
        default: // "auto" or anything else
            // Explicitly set to match current system appearance
            if NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                targetAppearance = NSAppearance(named: .darkAqua)
            } else {
                targetAppearance = NSAppearance(named: .aqua)
            }
        }
        
        // Only update appearance if it actually changed
        if window.appearance != targetAppearance {
            window.appearance = targetAppearance
        }
    }
    
    // MARK: - Context Menu
    
    private func showContextMenu() {
        let menu = NSMenu()
        
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit SimpleCP", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        // Set the menu and display it
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        
        // Clear the menu after it's dismissed so left-click still works
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.statusItem?.menu = nil
        }
    }
    
    @objc private func openSettings() {
        Task { @MainActor in
            WindowManager.shared.openSettingsWindow()
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Public Interface
    
    func isWindowVisible() -> Bool {
        return menuBarWindow?.isVisible ?? false
    }
    
    func makeWindowKey() {
        menuBarWindow?.makeKey()
    }
    
    func destroyWindow() {
        stopMonitoringClicksOutside()
        menuBarWindow?.orderOut(nil)
        menuBarWindow = nil
    }
    
    func showWindow() {
        showPanel()
    }
    
    func setContentView<Content: View>(_ view: Content) {
        self.contentView = AnyView(view)
        
        // Update existing window's content view if it exists
        if let window = menuBarWindow, let hostingController = window.contentViewController as? NSHostingController<AnyView> {
            #if DEBUG
            print("🔄 Updating existing hosting controller root view")
            #endif
            hostingController.rootView = AnyView(view)
            // Disable SwiftUI's automatic sizing
            hostingController.sizingOptions = []
            // Let AppKit handle the layout naturally - don't force it
        } else if let window = menuBarWindow {
            #if DEBUG
            print("🆕 Creating new hosting controller")
            #endif
            // Replace the content view controller
            let hostingView = NSHostingController(rootView: AnyView(view))
            // Disable SwiftUI's automatic sizing
            hostingView.sizingOptions = []
            window.contentViewController = hostingView
        }
    }
    
    func updatePopoverOpacity(_ opacity: Double) {
        guard let window = menuBarWindow else { return }
        
        // Only update if the value has actually changed (use epsilon for floating point comparison)
        if abs(window.alphaValue - opacity) > 0.001 {
            window.alphaValue = opacity
            window.isOpaque = (opacity >= 1.0)
            
            #if DEBUG
            print("🎨 Applying window opacity: \(Int(opacity * 100))%")
            #endif
        }
    }
    
    func updatePopoverAppearance() {
        applyOpacityAndAppearance()
    }
    
    func updateWindowSize() {
        guard let window = menuBarWindow else { 
            #if DEBUG
            print("⚠️ No window to update")
            #endif
            return 
        }
        guard let button = statusItem?.button else { return }
        
        // Get new window dimensions from single source of truth
        let windowDimensions = currentWindowDimensions
        
        #if DEBUG
        print("📏 Updating window size to: \(windowDimensions.width) x \(windowDimensions.height)")
        #endif
        
        // Calculate new position (centered under menu bar icon)
        if let buttonWindow = button.window {
            let buttonFrame = button.convert(button.bounds, to: nil)
            let screenFrame = buttonWindow.convertToScreen(buttonFrame)
            
            let xPos = screenFrame.midX - (windowDimensions.width / 2)
            let yPos = screenFrame.minY - windowDimensions.height - 8
            
            let newFrame = NSRect(x: xPos, y: yPos, width: windowDimensions.width, height: windowDimensions.height)
            
            // Update window size constraints first
            window.minSize = NSSize(width: windowDimensions.width, height: windowDimensions.height)
            window.maxSize = NSSize(width: windowDimensions.width, height: windowDimensions.height)
            
            // Resize the window (with animation if visible)
            if window.isVisible {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.25
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    window.animator().setFrame(newFrame, display: true)
                } completionHandler: {
                    // Force layout after animation completes
                    if let hostingController = window.contentViewController as? NSHostingController<AnyView> {
                        hostingController.view.setFrameSize(NSSize(width: windowDimensions.width, height: windowDimensions.height))
                    }
                }
            } else {
                window.setFrame(newFrame, display: true)
                if let hostingController = window.contentViewController as? NSHostingController<AnyView> {
                    hostingController.view.setFrameSize(NSSize(width: windowDimensions.width, height: windowDimensions.height))
                }
            }
        }
    }
    
    /// Recreates the window from scratch with the current size settings
    func recreateWindow(andShow: Bool = false) {
        // Check if window was visible before closing
        let wasVisible = menuBarWindow?.isVisible ?? false
        
        #if DEBUG
        let dims = WindowConfiguration.currentDimensions
        print("🔄 Recreating window: \(dims.width)x\(dims.height), wasVisible: \(wasVisible), andShow: \(andShow)")
        #endif
        
        // Close and destroy the existing window
        menuBarWindow?.orderOut(nil)
        menuBarWindow = nil
        
        // Show the panel immediately if it was visible before, or if explicitly requested
        if wasVisible || andShow {
            showPanel()
        }
    }
    
    /// Updates window dimensions without recreating (for live resize support)
    func updateWindowSize(width: Int, height: Int) {
        // Clamp dimensions to reasonable range
        let clampedWidth = max(250, min(800, width))
        let clampedHeight = max(300, min(800, height))
        
        // Save to UserDefaults
        UserDefaults.standard.set(clampedWidth, forKey: "windowWidth")
        UserDefaults.standard.set(clampedHeight, forKey: "windowHeight")
        
        #if DEBUG
        print("📏 Window size updated: \(clampedWidth)x\(clampedHeight) - will apply when window is next opened")
        #endif
        
        // If window exists but is not visible, just save the settings
        // The new size will be used when showPanel() is called next time
        guard let window = menuBarWindow, window.isVisible else {
            return
        }
        
        // Window is visible - resize it in place
        let newSize = NSSize(width: CGFloat(clampedWidth), height: CGFloat(clampedHeight))
        
        // Keep the window positioned below the menu bar icon
        if let button = statusItem?.button, let buttonWindow = button.window {
            let buttonFrame = button.convert(button.bounds, to: nil)
            let screenFrame = buttonWindow.convertToScreen(buttonFrame)
            
            let xPos = screenFrame.midX - (CGFloat(clampedWidth) / 2)
            let yPos = screenFrame.minY - CGFloat(clampedHeight) - 8
            
            let newFrame = NSRect(x: xPos, y: yPos, width: CGFloat(clampedWidth), height: CGFloat(clampedHeight))
            
            window.setFrame(newFrame, display: true, animate: true)
            
            // Update size constraints
            window.minSize = newSize
            window.maxSize = newSize
            
            // Update the hosting controller's view size
            if let hostingController = window.contentViewController as? NSHostingController<AnyView> {
                hostingController.view.setFrameSize(newSize)
            }
        }
    }
    
    /// Recreates the window from scratch with explicit dimensions
    func recreateWindow(width: Int, height: Int, andShow: Bool = false) {
        // Check if window was visible before closing
        let wasVisible = menuBarWindow?.isVisible ?? false
        
        // Clamp dimensions to reasonable range
        let clampedWidth = max(250, min(800, width))
        let clampedHeight = max(300, min(800, height))
        
        #if DEBUG
        print("🔄 Recreating window with size: \(clampedWidth)x\(clampedHeight), wasVisible: \(wasVisible), andShow: \(andShow)")
        #endif
        
        // Save to UserDefaults
        UserDefaults.standard.set(clampedWidth, forKey: "windowWidth")
        UserDefaults.standard.set(clampedHeight, forKey: "windowHeight")
        
        // Close and destroy the existing window
        menuBarWindow?.orderOut(nil)
        menuBarWindow = nil
        
        // Always recreate the window in memory so it's ready with the new size
        // But only show it if it was visible before, or if explicitly requested
        if wasVisible || andShow {
            showPanel()
        }
    }
}

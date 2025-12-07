//
//  FileMenuBarManager.swift
//  SimpleCP
//
//  Created by Smallfavor on 12/5/25.
//

import Foundation
//
//  MenuBarManager.swift
//  SimpleCP
//

import SwiftUI
import AppKit

class MenuBarManager: NSObject, NSWindowDelegate {
    static let shared = MenuBarManager()
    
    private var statusItem: NSStatusItem?
    private var menuBarWindow: NSPanel?
    var contentView: AnyView?
    
    override init() {
        super.init()
        setupStatusItem()
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
        if let window = menuBarWindow, window.isVisible {
            window.orderOut(nil)
        } else {
            showPanel()
        }
    }
    
    private func showPanel() {
        guard let button = statusItem?.button else { return }
        
        // Create window if it doesn't exist
        if menuBarWindow == nil {
            // Get the window size from UserDefaults to match SimpleCPApp settings
            let windowSizePreference = UserDefaults.standard.string(forKey: "windowSize") ?? "compact"
            let windowDimensions: (width: CGFloat, height: CGFloat)
            switch windowSizePreference {
            case "compact":
                windowDimensions = (400, 450)
            case "normal":
                windowDimensions = (450, 500)
            case "large":
                windowDimensions = (550, 650)
            default:
                windowDimensions = (450, 500)
            }
            
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: windowDimensions.width, height: windowDimensions.height),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.isFloatingPanel = true
            panel.becomesKeyOnlyIfNeeded = true
            panel.hidesOnDeactivate = false
            panel.delegate = self
            panel.hasShadow = true
            
            // Apply corner radius
            panel.contentView?.wantsLayer = true
            panel.contentView?.layer?.cornerRadius = 12
            panel.contentView?.layer?.masksToBounds = true
            
            if let contentView = contentView {
                let hostingView = NSHostingController(rootView: contentView)
                panel.contentViewController = hostingView
            }
            
            menuBarWindow = panel
            applyOpacityAndAppearance()
        }
        
        // Position window below menu bar icon
        if let window = menuBarWindow, let _ = button.window?.screen {
            let buttonFrame = button.convert(button.bounds, to: nil)
            let screenFrame = button.window?.convertToScreen(buttonFrame) ?? .zero
            
            let windowSize = window.frame.size
            
            let xPos = screenFrame.midX - (windowSize.width / 2)
            let yPos = screenFrame.minY - windowSize.height - 8
            
            window.setFrame(NSRect(x: xPos, y: yPos, width: windowSize.width, height: windowSize.height), display: true)
        }
        
        menuBarWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func applyOpacityAndAppearance() {
        guard let window = menuBarWindow else { return }
        
        let opacity = UserDefaults.standard.double(forKey: "windowOpacity")
        let alphaValue = opacity > 0 ? opacity : 0.95
        
        window.alphaValue = alphaValue
        window.isOpaque = false
        window.backgroundColor = .clear
        
        let theme = UserDefaults.standard.string(forKey: "theme") ?? "auto"
        switch theme.lowercased() {
        case "light":
            window.appearance = NSAppearance(named: .aqua)
        case "dark":
            window.appearance = NSAppearance(named: .darkAqua)
        default: // "auto" or anything else
            // Explicitly set to match current system appearance
            if NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                window.appearance = NSAppearance(named: .darkAqua)
            } else {
                window.appearance = NSAppearance(named: .aqua)
            }
        }
    }
    
    // MARK: - NSWindowDelegate
    
    func windowDidResignKey(_ notification: Notification) {
        // Hide panel when it loses focus
        menuBarWindow?.orderOut(nil)
    }
    
    // MARK: - Context Menu
    
    private func showContextMenu() {
        guard let button = statusItem?.button else { return }
        
        let menu = NSMenu()
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit SimpleCP", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
        button.performClick(nil)
        
        DispatchQueue.main.async { [weak self] in
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
    
    func setContentView<Content: View>(_ view: Content) {
        self.contentView = AnyView(view)
        
        // Update existing window's content view if it exists
        if let window = menuBarWindow, let hostingController = window.contentViewController as? NSHostingController<AnyView> {
            hostingController.rootView = AnyView(view)
        } else if let window = menuBarWindow {
            // Replace the content view controller
            let hostingView = NSHostingController(rootView: AnyView(view))
            window.contentViewController = hostingView
        }
    }
    
    func updatePopoverOpacity(_ opacity: Double) {
        guard let window = menuBarWindow else { return }
        window.alphaValue = opacity
        window.isOpaque = (opacity >= 1.0)
    }
    
    func updatePopoverAppearance() {
        applyOpacityAndAppearance()
    }
    
    func updateWindowSize() {
        guard let window = menuBarWindow else { return }
        guard let button = statusItem?.button else { return }
        
        // Get new window dimensions
        let windowSizePreference = UserDefaults.standard.string(forKey: "windowSize") ?? "compact"
        let windowDimensions: (width: CGFloat, height: CGFloat)
        switch windowSizePreference {
        case "compact":
            windowDimensions = (400, 450)
        case "normal":
            windowDimensions = (450, 500)
        case "large":
            windowDimensions = (550, 650)
        default:
            windowDimensions = (450, 500)
        }
        
        // Calculate new position (centered under menu bar icon)
        if let buttonWindow = button.window {
            let buttonFrame = button.convert(button.bounds, to: nil)
            let screenFrame = buttonWindow.convertToScreen(buttonFrame)
            
            let xPos = screenFrame.midX - (windowDimensions.width / 2)
            let yPos = screenFrame.minY - windowDimensions.height - 8
            
            let newFrame = NSRect(x: xPos, y: yPos, width: windowDimensions.width, height: windowDimensions.height)
            
            // Resize the window (with animation if visible)
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().setFrame(newFrame, display: true)
            }
            
            // Force the hosting controller to update its size
            if let hostingController = window.contentViewController as? NSHostingController<AnyView> {
                hostingController.sizingOptions = [.intrinsicContentSize]
                hostingController.view.needsLayout = true
                hostingController.view.layoutSubtreeIfNeeded()
            }
        }
    }
}

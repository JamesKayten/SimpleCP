//
//  MenuBarManager.swift
//  SimpleCP
//
//  Menu bar status item and panel management.
//  Extensions: +WindowSize
//

import Foundation
import SwiftUI
import AppKit

// Custom NSPanel that can accept keyboard input when explicitly made key
class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return false }
}

class MenuBarManager: NSObject {
    static let shared = MenuBarManager()

    var statusItem: NSStatusItem?
    var menuBarWindow: NSPanel?
    var contentView: AnyView?
    private var eventMonitor: Any?

    var previouslyActiveApp: NSRunningApplication?

    var currentWindowDimensions: (width: CGFloat, height: CGFloat) {
        let width = UserDefaults.standard.integer(forKey: "windowWidth")
        let height = UserDefaults.standard.integer(forKey: "windowHeight")
        return (width: CGFloat(width > 0 ? width : 400), height: CGFloat(height > 0 ? height : 450))
    }

    override init() {
        super.init()
        setupStatusItem()
    }

    deinit { stopMonitoringClicksOutside() }

    // MARK: - Status Item Setup

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
        capturePreviouslyActiveApp()

        if event.type == .rightMouseUp { showContextMenu() }
        else { togglePanel() }
    }

    private func togglePanel() {
        if let window = menuBarWindow, window.isVisible {
            window.orderOut(nil)
            stopMonitoringClicksOutside()
        } else {
            showPanel()
        }
    }

    // MARK: - Click Outside Detection

    func startMonitoringClicksOutside() {
        stopMonitoringClicksOutside()

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let window = self.menuBarWindow, window.isVisible else { return }
            let clickLocation = NSEvent.mouseLocation

            if !window.frame.contains(clickLocation) {
                if let button = self.statusItem?.button, let buttonWindow = button.window {
                    let buttonFrame = button.convert(button.bounds, to: nil)
                    let screenButtonFrame = buttonWindow.convertToScreen(buttonFrame)

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

    // MARK: - Panel Display

    func showPanel() {
        guard let button = statusItem?.button else { return }
        capturePreviouslyActiveApp()

        if menuBarWindow == nil {
            let windowDimensions = currentWindowDimensions

            let panel = KeyablePanel(
                contentRect: NSRect(x: 0, y: 0, width: windowDimensions.width, height: windowDimensions.height),
                styleMask: [.borderless], backing: .buffered, defer: false
            )

            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.isFloatingPanel = true
            panel.hidesOnDeactivate = false
            panel.hasShadow = true
            panel.minSize = NSSize(width: windowDimensions.width, height: windowDimensions.height)
            panel.maxSize = NSSize(width: windowDimensions.width, height: windowDimensions.height)

            panel.contentView?.wantsLayer = true
            panel.contentView?.layer?.cornerRadius = 12
            panel.contentView?.layer?.masksToBounds = true

            if let contentView = contentView {
                let hostingView = NSHostingController(rootView: contentView)
                hostingView.sizingOptions = []
                panel.contentViewController = hostingView
            }

            menuBarWindow = panel

            if let buttonWindow = button.window {
                let buttonFrame = button.convert(button.bounds, to: nil)
                let screenFrame = buttonWindow.convertToScreen(buttonFrame)
                let xPos = screenFrame.midX - (windowDimensions.width / 2)
                let yPos = screenFrame.minY - windowDimensions.height - 8
                panel.setFrame(NSRect(x: xPos, y: yPos, width: windowDimensions.width, height: windowDimensions.height), display: false)
            }

            applyOpacityAndAppearance()
            panel.orderFront(nil)
            startMonitoringClicksOutside()
        } else {
            menuBarWindow?.orderFront(nil)
            startMonitoringClicksOutside()
        }
    }

    private func applyOpacityAndAppearance() {
        guard let window = menuBarWindow else { return }

        let opacity = UserDefaults.standard.double(forKey: "windowOpacity")
        let alphaValue = opacity > 0 ? opacity : 0.95

        if abs(window.alphaValue - alphaValue) > 0.001 {
            window.alphaValue = alphaValue
            window.isOpaque = false
            window.backgroundColor = .clear
        }

        let theme = UserDefaults.standard.string(forKey: "theme") ?? "auto"
        let targetAppearance: NSAppearance?

        switch theme.lowercased() {
        case "light": targetAppearance = NSAppearance(named: .aqua)
        case "dark": targetAppearance = NSAppearance(named: .darkAqua)
        default:
            if NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                targetAppearance = NSAppearance(named: .darkAqua)
            } else {
                targetAppearance = NSAppearance(named: .aqua)
            }
        }

        if window.appearance != targetAppearance { window.appearance = targetAppearance }
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

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.statusItem?.menu = nil
        }
    }

    @objc private func openSettings() {
        Task { @MainActor in WindowManager.shared.openSettingsWindow() }
    }

    @objc private func quitApp() { NSApplication.shared.terminate(nil) }

    // MARK: - Public Interface

    func isWindowVisible() -> Bool { return menuBarWindow?.isVisible ?? false }

    func makeWindowKey() {
        NSApp.activate(ignoringOtherApps: true)
        menuBarWindow?.makeKey()
    }

    func hidePopover() {
        menuBarWindow?.orderOut(nil)
        stopMonitoringClicksOutside()
        previouslyActiveApp = nil
    }

    private func capturePreviouslyActiveApp() {
        let workspace = NSWorkspace.shared
        let newActiveApp = workspace.runningApplications.first { app in
            app.isActive && app.activationPolicy == .regular &&
            app.bundleIdentifier != Bundle.main.bundleIdentifier && !app.isTerminated
        }

        if let app = newActiveApp { previouslyActiveApp = app }
    }

    func destroyWindow() {
        stopMonitoringClicksOutside()
        menuBarWindow?.orderOut(nil)
        menuBarWindow = nil
    }

    func showWindow() { showPanel() }

    func setContentView<Content: View>(_ view: Content) {
        self.contentView = AnyView(view)

        if let window = menuBarWindow, let hostingController = window.contentViewController as? NSHostingController<AnyView> {
            hostingController.rootView = AnyView(view)
            hostingController.sizingOptions = []
        } else if let window = menuBarWindow {
            let hostingView = NSHostingController(rootView: AnyView(view))
            hostingView.sizingOptions = []
            window.contentViewController = hostingView
        }
    }

    func updatePopoverOpacity(_ opacity: Double) {
        guard let window = menuBarWindow else { return }
        if abs(window.alphaValue - opacity) > 0.001 {
            window.alphaValue = opacity
            window.isOpaque = (opacity >= 1.0)
        }
    }

    func updatePopoverAppearance() { applyOpacityAndAppearance() }
}

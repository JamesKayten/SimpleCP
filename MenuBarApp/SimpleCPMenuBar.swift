import Cocoa
import SwiftUI

@main
class SimpleCPMenuBarApp: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var eventMonitor: EventMonitor?
    var apiClient: SimpleCPAPIClient!
    var hotkeyManager: HotkeyManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize API client
        apiClient = SimpleCPAPIClient(baseURL: "http://127.0.0.1:8000")

        // Initialize hotkey manager
        hotkeyManager = HotkeyManager(apiClient: apiClient)
        hotkeyManager.registerDefaultHotkeys()

        // Create status bar item
        setupMenuBar()

        // Create popover for main window
        setupPopover()

        // Monitor for clicks outside popover
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let popover = self?.popover, popover.isShown {
                self?.closePopover(event)
            }
        }

        // Start polling clipboard count
        startClipboardCountTimer()
    }

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "SimpleCP")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        // Create menu
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Show SimpleCP", action: #selector(showMainWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quick Copy", action: #selector(quickCopyLast), keyEquivalent: "c"))
        menu.addItem(NSMenuItem(title: "Clear History", action: #selector(clearHistory), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit SimpleCP", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 400, height: 500)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: QuickAccessView(apiClient: apiClient)
        )
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let popover = popover {
            if popover.isShown {
                closePopover(sender)
            } else {
                showPopover(sender)
            }
        }
    }

    func showPopover(_ sender: AnyObject?) {
        if let button = statusItem?.button {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            eventMonitor?.start()
        }
    }

    func closePopover(_ sender: AnyObject?) {
        popover?.performClose(sender)
        eventMonitor?.stop()
    }

    @objc func showMainWindow() {
        // Launch or activate main SimpleCP window
        NSWorkspace.shared.launchApplication(
            withBundleIdentifier: "com.simplecp.app",
            options: [],
            additionalEventParamDescriptor: nil,
            launchIdentifier: nil
        )
    }

    @objc func quickCopyLast() {
        Task {
            do {
                let recent = try await apiClient.getRecentHistory()
                if let first = recent.first {
                    try await apiClient.copyToClipboard(clipId: first.clipId)
                    showNotification(title: "Copied", message: "Last clipboard item copied")
                }
            } catch {
                print("Error quick copying: \(error)")
            }
        }
    }

    @objc func clearHistory() {
        let alert = NSAlert()
        alert.messageText = "Clear Clipboard History?"
        alert.informativeText = "This will delete all clipboard history. This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            Task {
                do {
                    try await apiClient.clearHistory()
                    showNotification(title: "History Cleared", message: "All clipboard history has been deleted")
                } catch {
                    print("Error clearing history: \(error)")
                }
            }
        }
    }

    @objc func showSettings() {
        let settingsView = SettingsView(apiClient: apiClient)
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "SimpleCP Settings"
        window.setContentSize(NSSize(width: 600, height: 400))
        window.styleMask = [.titled, .closable, .resizable]
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(self)
    }

    func startClipboardCountTimer() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task {
                await self?.updateClipboardCount()
            }
        }
    }

    func updateClipboardCount() async {
        do {
            let stats = try await apiClient.getStats()
            await MainActor.run {
                if let button = statusItem?.button {
                    button.title = " \(stats.historyCount)"
                }
            }
        } catch {
            print("Error updating clipboard count: \(error)")
        }
    }

    func showNotification(title: String, message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
}

// MARK: - Event Monitor for detecting clicks outside popover
class EventMonitor {
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> Void

    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> Void) {
        self.mask = mask
        self.handler = handler
    }

    deinit {
        stop()
    }

    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
    }

    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}

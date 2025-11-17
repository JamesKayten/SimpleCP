import Cocoa
import Carbon

class HotkeyManager {
    private var hotkeys: [String: EventHotKeyRef] = [:]
    private let apiClient: SimpleCPAPIClient
    private var eventHandler: EventHandlerRef?

    struct Hotkey {
        let keyCode: UInt32
        let modifiers: UInt32
        let action: String
    }

    // Default hotkeys
    static let defaultHotkeys: [String: Hotkey] = [
        "quickToggle": Hotkey(keyCode: 9, modifiers: UInt32(cmdKey | shiftKey), action: "toggle"), // Cmd+Shift+V
        "quickCopy": Hotkey(keyCode: 8, modifiers: UInt32(cmdKey | shiftKey), action: "quickCopy"), // Cmd+Shift+C
        "clearHistory": Hotkey(keyCode: 6, modifiers: UInt32(cmdKey | shiftKey), action: "clearHistory"), // Cmd+Shift+X
    ]

    init(apiClient: SimpleCPAPIClient) {
        self.apiClient = apiClient
        setupEventHandler()
    }

    deinit {
        unregisterAllHotkeys()
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
    }

    func setupEventHandler() {
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, event, userData) -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }

            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()

            var hotkeyID = EventHotKeyID()
            GetEventParameter(
                event,
                UInt32(kEventParamDirectObject),
                UInt32(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotkeyID
            )

            manager.handleHotkeyPress(id: hotkeyID.id)

            return noErr
        }, 1, &eventSpec, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)
    }

    func registerDefaultHotkeys() {
        for (name, hotkey) in Self.defaultHotkeys {
            registerHotkey(name: name, hotkey: hotkey)
        }
    }

    func registerHotkey(name: String, hotkey: Hotkey) {
        var hotkeyRef: EventHotKeyRef?
        var hotkeyID = EventHotKeyID(signature: OSType(0x484B4559), id: UInt32(hotkeys.count + 1)) // 'HKEY'

        let status = RegisterEventHotKey(
            hotkey.keyCode,
            hotkey.modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )

        if status == noErr, let ref = hotkeyRef {
            hotkeys[name] = ref
            print("Registered hotkey: \(name)")
        } else {
            print("Failed to register hotkey: \(name)")
        }
    }

    func unregisterHotkey(name: String) {
        if let hotkeyRef = hotkeys[name] {
            UnregisterEventHotKey(hotkeyRef)
            hotkeys.removeValue(forKey: name)
        }
    }

    func unregisterAllHotkeys() {
        for (name, _) in hotkeys {
            unregisterHotkey(name: name)
        }
    }

    private func handleHotkeyPress(id: UInt32) {
        // Find which hotkey was pressed
        let index = Int(id) - 1
        let hotkeyNames = Array(hotkeys.keys)

        guard index < hotkeyNames.count else { return }

        let hotkeyName = hotkeyNames[index]

        // Execute action
        executeHotkeyAction(for: hotkeyName)
    }

    private func executeHotkeyAction(for name: String) {
        guard let hotkey = Self.defaultHotkeys[name] else { return }

        switch hotkey.action {
        case "toggle":
            toggleQuickAccess()
        case "quickCopy":
            quickCopyLast()
        case "clearHistory":
            promptClearHistory()
        default:
            break
        }
    }

    private func toggleQuickAccess() {
        // Post notification to toggle popover
        NotificationCenter.default.post(name: .togglePopover, object: nil)
    }

    private func quickCopyLast() {
        Task {
            do {
                let recent = try await apiClient.getRecentHistory()
                if let first = recent.first {
                    try await apiClient.copyToClipboard(clipId: first.clipId)
                    showNotification(title: "Quick Copy", message: "Last item copied to clipboard")
                }
            } catch {
                print("Error in quick copy: \(error)")
            }
        }
    }

    private func promptClearHistory() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Clear History?"
            alert.informativeText = "This will delete all clipboard history."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Clear")
            alert.addButton(withTitle: "Cancel")

            if alert.runModal() == .alertFirstButtonReturn {
                Task {
                    do {
                        try await self.apiClient.clearHistory()
                        self.showNotification(title: "History Cleared", message: "All history deleted")
                    } catch {
                        print("Error clearing history: \(error)")
                    }
                }
            }
        }
    }

    private func showNotification(title: String, message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let togglePopover = Notification.Name("togglePopover")
}

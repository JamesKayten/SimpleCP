//
//  RecentClipsColumn.swift
//  SimpleCP
//
//  Created by SimpleCP
//

import SwiftUI
import ApplicationServices  // For AXIsProcessTrusted
import Carbon.HIToolbox  // For kVK_ANSI_V key code

struct RecentClipsColumn: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    let searchText: String
    let onSaveAsSnippet: (ClipItem) -> Void

    @State private var hoveredClipId: UUID?
    @State private var selectedClipIds: Set<UUID> = []
    @State private var expandedGroups: Set<String> = []
    @Environment(\.fontPreferences) private var fontPrefs

    // Configurable paste delays (in seconds)
    @AppStorage("pasteHideDelay") private var pasteHideDelay = 0.1
    @AppStorage("pasteActivateDelay") private var pasteActivateDelay = 0.4

    private var filteredClips: [ClipItem] {
        if searchText.isEmpty {
            return clipboardManager.clipHistory
        }
        // Filter clips based on search text
        return clipboardManager.clipHistory.filter { clip in
            clip.content.localizedCaseInsensitiveContains(searchText) ||
            clip.preview.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var recentClips: [ClipItem] {
        Array(filteredClips.prefix(10))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column Header
            HStack {
                Image(systemName: "doc.on.clipboard")
                    .foregroundColor(.secondary)
                Text("CLIPS")
                    .font(fontPrefs.interfaceFont(weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                
                // Trash button for deleting selected clips
                Button(action: {
                    deleteSelectedClips()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(selectedClipIds.isEmpty ? .secondary : .red)
                }
                .buttonStyle(.plain)
                .help(selectedClipIds.isEmpty ? "Select clips to delete" : "Delete \(selectedClipIds.count) selected clip(s)")
                .disabled(selectedClipIds.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            .contextMenu {
                Button(action: {
                    SaveSnippetWindowManager.shared.showDialog(
                        content: clipboardManager.currentClipboard,
                        clipboardManager: clipboardManager,
                        onDismiss: {}
                    )
                }) {
                    Label("Save Current Clipboard as Snippet", systemImage: "square.and.arrow.down")
                }
                
                Divider()
                
                Button(action: {
                    // Select all clips
                    selectedClipIds = Set(recentClips.map { $0.id })
                }) {
                    Label("Select All Clips", systemImage: "checkmark.circle")
                }
                
                Button(action: {
                    // Deselect all
                    selectedClipIds.removeAll()
                }) {
                    Label("Deselect All", systemImage: "circle")
                }
                
                Divider()
                
                Text("\(clipboardManager.clipHistory.count) clips in history")
                    .foregroundColor(.secondary)
            }

            Divider()

            // Clips List - Optimized for mouse wheel scrolling
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 1) {
                    // Recent 10 clips
                    ForEach(Array(recentClips.enumerated()), id: \.element.id) { index, clip in
                        ClipItemRow(
                            index: index + 1,
                            clip: clip,
                            isHovered: hoveredClipId == clip.id,
                            isSelected: selectedClipIds.contains(clip.id),
                            onCopy: {
                                // Single click = copy and paste immediately
                                clipboardManager.copyToClipboard(clip.content)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    pasteToActiveApp()
                                }
                            },
                            onToggleSelect: {
                                if selectedClipIds.contains(clip.id) {
                                    selectedClipIds.remove(clip.id)
                                } else {
                                    selectedClipIds.insert(clip.id)
                                }
                            },
                            onSelectMultiple: { upToIndex in
                                // Select all clips from 0 to upToIndex
                                let clipsToSelect = Array(recentClips.prefix(upToIndex))
                                for clipItem in clipsToSelect {
                                    selectedClipIds.insert(clipItem.id)
                                }
                            },
                            onSave: {
                                onSaveAsSnippet(clip)
                            }
                        )
                        .onHover { isHovered in
                            hoveredClipId = isHovered ? clip.id : nil
                        }
                        .contextMenu {
                            Button("Copy Only (No Paste)") {
                                clipboardManager.copyToClipboard(clip.content)
                            }
                            Button("Save as Snippet...") {
                                onSaveAsSnippet(clip)
                            }
                            Divider()
                            Button(selectedClipIds.contains(clip.id) ? "Deselect" : "Select") {
                                if selectedClipIds.contains(clip.id) {
                                    selectedClipIds.remove(clip.id)
                                } else {
                                    selectedClipIds.insert(clip.id)
                                }
                            }
                            Button("Remove from History") {
                                clipboardManager.removeFromHistory(item: clip)
                                selectedClipIds.remove(clip.id)
                            }
                        }
                    }

                    // Grouped history folders
                    if filteredClips.count > 10 {
                        Divider()
                            .padding(.vertical, 8)

                        ForEach(historyGroups, id: \.range) { group in
                            HistoryGroupDisclosure(
                                range: group.range,
                                clips: group.clips,
                                isExpanded: expandedGroups.contains(group.range),
                                onToggle: {
                                    if expandedGroups.contains(group.range) {
                                        expandedGroups.remove(group.range)
                                    } else {
                                        expandedGroups.insert(group.range)
                                    }
                                },
                                hoveredClipId: $hoveredClipId,
                                selectedClipIds: $selectedClipIds,
                                onSaveAsSnippet: onSaveAsSnippet,
                                clipboardManager: clipboardManager,
                                onPasteToActiveApp: pasteToActiveApp,
                                onCopyAndRestoreFocus: copyAndRestoreFocus
                            )
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - History Groups

    private var historyGroups: [(range: String, clips: [ClipItem])] {
        var groups: [(String, [ClipItem])] = []
        let total = filteredClips.count

        for i in stride(from: 11, to: total + 1, by: 10) {
            let start = i
            let end = min(i + 9, total)
            let clipsInRange = Array(filteredClips[safe: start - 1..<end] ?? [])
            if !clipsInRange.isEmpty {
                groups.append(("\(start) - \(end)", clipsInRange))
            }
        }

        return groups
    }
    
    // MARK: - Actions

    private func deleteSelectedClips() {
        guard !selectedClipIds.isEmpty else { return }
        
        let clipsToDelete = clipboardManager.clipHistory.filter { selectedClipIds.contains($0.id) }
        
        for clip in clipsToDelete {
            clipboardManager.removeFromHistory(item: clip)
        }
        
        selectedClipIds.removeAll()
    }
    
    private func copyAndRestoreFocus(_ content: String) {
        // Copy the content
        clipboardManager.copyToClipboard(content)
        
        // Restore focus to the previously active app
        restoreFocusToPreviousApp()
    }
    
    private func restoreFocusToPreviousApp() {
        // Get the previously active app that was captured when SimpleCP opened
        guard let targetApp = MenuBarManager.shared.previouslyActiveApp,
              !targetApp.isTerminated else {
            print("⚠️ No valid target app to restore focus to")
            return
        }
        
        // Small delay to ensure clipboard is updated
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            targetApp.activate(options: [.activateIgnoringOtherApps])
            print("✅ Restored focus to: \(targetApp.localizedName ?? "unknown")")
        }
    }
    
    private func pasteToActiveApp() {
        // Get the previously active application that was captured when SimpleCP opened
        let targetApp = MenuBarManager.shared.previouslyActiveApp

        if let app = targetApp {
            print("🎯 Target app: \(app.localizedName ?? "unknown")")
        } else {
            print("⚠️ No target app captured - will try to find frontmost app")
        }

        // Hide the SimpleCP window first
        MenuBarManager.shared.hidePopover()

        // Give a moment for the window to hide (configurable)
        DispatchQueue.main.asyncAfter(deadline: .now() + pasteHideDelay) {
            // Activate the target app to restore focus
            if let app = targetApp, !app.isTerminated {
                app.activate(options: [.activateIgnoringOtherApps])
                print("✅ Activated: \(app.localizedName ?? "unknown")")

                // Wait for focus to fully shift (configurable)
                DispatchQueue.main.asyncAfter(deadline: .now() + self.pasteActivateDelay) { [self] in
                    self.executePaste()
                }
            } else {
                // Fallback: try to find any frontmost app
                let workspace = NSWorkspace.shared
                if let frontmost = workspace.runningApplications.first(where: {
                    $0.activationPolicy == .regular &&
                    $0.bundleIdentifier != Bundle.main.bundleIdentifier &&
                    !$0.isTerminated
                }) {
                    frontmost.activate(options: [.activateIgnoringOtherApps])
                    print("✅ Activated (fallback): \(frontmost.localizedName ?? "unknown")")
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.pasteActivateDelay) {
                        self.executePaste()
                    }
                } else {
                    print("❌ No app found to paste to")
                    self.executePaste() // Try anyway
                }
            }
        }
    }
    
    private func executePaste() {
        // Use CGEvents for native keyboard simulation (requires accessibility permission)
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            print("❌ Failed to create CGEventSource")
            showPermissionDeniedAlert()
            return
        }

        // V key = 0x09 (kVK_ANSI_V)
        let keyCode: CGKeyCode = 0x09

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            print("❌ Failed to create CGEvents")
            showPermissionDeniedAlert()
            return
        }

        // Add Command modifier
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        // Post the events
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)

        print("⌨️ Executed paste via CGEvents (⌘V)")
    }
    
    private func showPermissionDeniedAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = """
            The "Paste Immediately" feature requires Accessibility permission to simulate keyboard input.
            
            To enable this feature:
            
            1. Click "Open System Settings" below
            2. Find "SimpleCP" in the Accessibility list
            3. Toggle the switch ON
            4. **Quit and restart SimpleCP** (⌘Q then reopen)
            
            Note: This is optional. You can still copy clips normally without this permission.
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Not Now")
            
            if let icon = NSImage(systemSymbolName: "hand.tap.fill", accessibilityDescription: "Permission") {
                alert.icon = icon
            }
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                AccessibilityPermissionManager.shared.openAccessibilitySettings()
            }
        }
    }
}

// MARK: - Clip Item Row

struct ClipItemRow: View {
    let index: Int
    let clip: ClipItem
    let isHovered: Bool
    let isSelected: Bool
    let onCopy: () -> Void
    let onToggleSelect: () -> Void
    let onSelectMultiple: (Int) -> Void
    let onSave: () -> Void
    
    @State private var showPopover = false
    @State private var hoverTimer: Timer?
    @Environment(\.fontPreferences) private var fontPrefs
    @AppStorage("showSnippetPreviews") private var showSnippetPreviews = false
    @AppStorage("clipPreviewDelay") private var clipPreviewDelay = 0.7
    @EnvironmentObject var clipboardManager: ClipboardManager

    var body: some View {
        HStack(spacing: 8) {
            // Selection checkbox with Option+Click support
            SelectionButton(
                isSelected: isSelected,
                index: index,
                clipboardManager: clipboardManager,
                onToggleSelect: onToggleSelect,
                onSelectMultiple: onSelectMultiple
            )

            // Content preview (more compact - no timestamp shown)
            Text(clip.preview)
                .font(fontPrefs.clipContentFont())
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : (isHovered ? Color(NSColor.controlBackgroundColor) : Color.clear))
        .contentShape(Rectangle())
        .onTapGesture {
            // Regular click: Copy just this clip
            onCopy()
        }
        .popover(isPresented: $showPopover, arrowEdge: .trailing) {
            ClipContentPopover(clip: clip)
        }
        .onHover { hovering in
            if hovering && showSnippetPreviews {
                // Show popover after user-configured delay
                hoverTimer = Timer.scheduledTimer(withTimeInterval: clipPreviewDelay, repeats: false) { _ in
                    showPopover = true
                }
            } else {
                // Cancel timer and hide popover
                hoverTimer?.invalidate()
                hoverTimer = nil
                showPopover = false
            }
        }
    }
}

// MARK: - Selection Button with Option+Click

struct SelectionButton: View {
    let isSelected: Bool
    let index: Int
    let clipboardManager: ClipboardManager
    let onToggleSelect: () -> Void
    let onSelectMultiple: (Int) -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: {
            // Check if Option key is held
            if NSEvent.modifierFlags.contains(.option) {
                onSelectMultiple(index)
            } else {
                onToggleSelect()
            }
        }) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .font(.system(size: 14))
        }
        .buttonStyle(.plain)
        .fixedSize()
        .onHover { hovering in
            isHovering = hovering
        }
        .help(NSEvent.modifierFlags.contains(.option) ? "Select all clips up to #\(index)" : "Select this clip")
    }
}

// MARK: - Clip Content Popover

struct ClipContentPopover: View {
    let clip: ClipItem
    @Environment(\.fontPreferences) private var fontPrefs
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: contentTypeIcon)
                    .foregroundColor(.secondary)
                Text(contentTypeLabel)
                    .font(fontPrefs.interfaceFont(weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text(clip.displayTime)
                    .font(fontPrefs.interfaceFont())
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Full content
            ScrollView {
                Text(clip.content)
                    .font(fontPrefs.clipContentFont())
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: 400, maxHeight: 300)
            
            // Footer with character count
            HStack {
                Text("\(clip.content.count) characters")
                    .font(fontPrefs.interfaceFont())
                    .foregroundColor(.secondary)
                Spacer()
                if clip.content.components(separatedBy: .newlines).count > 1 {
                    Text("\(clip.content.components(separatedBy: .newlines).count) lines")
                        .font(fontPrefs.interfaceFont())
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .frame(minWidth: 300)
    }
    
    private var contentTypeIcon: String {
        switch clip.contentType {
        case .text: return "doc.text"
        case .url: return "link"
        case .email: return "envelope"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .unknown: return "doc.questionmark"
        }
    }
    
    private var contentTypeLabel: String {
        switch clip.contentType {
        case .text: return "Text"
        case .url: return "URL"
        case .email: return "Email"
        case .code: return "Code"
        case .unknown: return "Unknown"
        }
    }
}

// MARK: - History Group Disclosure

struct HistoryGroupDisclosure: View {
    let range: String
    let clips: [ClipItem]
    let isExpanded: Bool
    let onToggle: () -> Void
    @Binding var hoveredClipId: UUID?
    @Binding var selectedClipIds: Set<UUID>
    let onSaveAsSnippet: (ClipItem) -> Void
    let clipboardManager: ClipboardManager
    let onPasteToActiveApp: () -> Void
    let onCopyAndRestoreFocus: (String) -> Void
    
    @State private var isHovered: Bool = false
    @State private var showFlyout: Bool = false
    @State private var hoverTimer: Timer?
    @State private var flyoutHovered: Bool = false
    @AppStorage("clipGroupFlyoutDelay") private var clipGroupFlyoutDelay = 0.5

    var body: some View {
        VStack(spacing: 0) {
            // Header button
            Button(action: onToggle) {
                HStack(spacing: 8) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 12)
                    
                    Image(systemName: "folder.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Text(range)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("(\(clips.count) clips)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isHovered ? Color(NSColor.controlBackgroundColor) : Color.clear)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                print("🔶 GROUP HOVER: \(hovering) on range: \(range)")
                isHovered = hovering
                if hovering {
                    hoverTimer?.invalidate()
                    hoverTimer = Timer.scheduledTimer(withTimeInterval: clipGroupFlyoutDelay, repeats: false) { _ in
                        print("🟦 SHOWING GROUP FLYOUT for range: \(range)")
                        showFlyout = true
                    }
                } else {
                    hoverTimer?.invalidate()
                    hoverTimer = nil
                    // Keep flyout open if mouse is over flyout
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if !isHovered && !flyoutHovered {
                            showFlyout = false
                        }
                    }
                }
            }
            .popover(isPresented: $showFlyout, arrowEdge: .trailing) {
                ClipGroupFlyout(
                    range: range,
                    clips: clips,
                    clipboardManager: clipboardManager,
                    onSaveAsSnippet: onSaveAsSnippet,
                    onPasteToActiveApp: onPasteToActiveApp,
                    onHoverChange: { hovering in
                        flyoutHovered = hovering
                    },
                    onClose: { 
                        showFlyout = false
                        flyoutHovered = false
                    }
                )
                .onAppear {
                    print("✅ GROUP FLYOUT APPEARED for range: \(range)")
                    flyoutHovered = true
                }
                .onDisappear {
                    flyoutHovered = false
                }
            }
            
            // Expanded clips
            if isExpanded {
                VStack(spacing: 1) {
                    ForEach(Array(clips.enumerated()), id: \.element.id) { index, clip in
                        ClipItemRow(
                            index: Int(range.components(separatedBy: " - ").first ?? "0")! + index,
                            clip: clip,
                            isHovered: hoveredClipId == clip.id,
                            isSelected: selectedClipIds.contains(clip.id),
                            onCopy: {
                                // Single click = copy and paste immediately
                                clipboardManager.copyToClipboard(clip.content)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    onPasteToActiveApp()
                                }
                            },
                            onToggleSelect: {
                                if selectedClipIds.contains(clip.id) {
                                    selectedClipIds.remove(clip.id)
                                } else {
                                    selectedClipIds.insert(clip.id)
                                }
                            },
                            onSelectMultiple: { upToIndex in
                                // Select all clips from history up to the specified index
                                let clipsToSelect = Array(clipboardManager.clipHistory.prefix(upToIndex))
                                for clipItem in clipsToSelect {
                                    selectedClipIds.insert(clipItem.id)
                                }
                            },
                            onSave: {
                                onSaveAsSnippet(clip)
                            }
                        )
                        .onHover { isHovered in
                            hoveredClipId = isHovered ? clip.id : nil
                        }
                        .contextMenu {
                            Button("Paste Immediately") {
                                clipboardManager.copyToClipboard(clip.content)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    onPasteToActiveApp()
                                }
                            }
                            
                            Divider()
                            
                            Button("Copy") {
                                clipboardManager.copyToClipboard(clip.content)
                            }
                            Button("Save as Snippet...") {
                                onSaveAsSnippet(clip)
                            }
                            Divider()
                            Button(selectedClipIds.contains(clip.id) ? "Deselect" : "Select") {
                                if selectedClipIds.contains(clip.id) {
                                    selectedClipIds.remove(clip.id)
                                } else {
                                    selectedClipIds.insert(clip.id)
                                }
                            }
                            Button("Remove from History") {
                                clipboardManager.removeFromHistory(item: clip)
                                selectedClipIds.remove(clip.id)
                            }
                        }
                    }
                }
                .padding(.leading, 20)
            }
        }
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe range: Range<Index>) -> ArraySlice<Element>? {
        if range.lowerBound >= 0 && range.upperBound <= count {
            return self[range]
        }
        return nil
    }
}

// MARK: - Clip Group Flyout

struct ClipGroupFlyout: View {
    let range: String
    let clips: [ClipItem]
    let clipboardManager: ClipboardManager
    let onSaveAsSnippet: (ClipItem) -> Void
    let onPasteToActiveApp: () -> Void
    let onHoverChange: (Bool) -> Void
    let onClose: () -> Void
    
    @State private var hoveredClipId: UUID?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                Text(range)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(clips.count)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Clips List
            if clips.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No clips")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(clips) { clip in
                            FlyoutClipRow(
                                clip: clip,
                                isHovered: hoveredClipId == clip.id,
                                onPaste: {
                                    clipboardManager.copyToClipboard(clip.content)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        onPasteToActiveApp()
                                        onClose()
                                    }
                                },
                                onCopy: {
                                    clipboardManager.copyToClipboard(clip.content)
                                },
                                onSave: {
                                    onSaveAsSnippet(clip)
                                },
                                onDelete: {
                                    clipboardManager.removeFromHistory(item: clip)
                                }
                            )
                            .onHover { isHovered in
                                hoveredClipId = isHovered ? clip.id : nil
                            }
                        }
                    }
                }
                .frame(maxHeight: 400)
            }
        }
        .frame(minWidth: 300, maxWidth: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .onHover { hovering in
            onHoverChange(hovering)
        }
    }
}

// MARK: - Flyout Clip Row

struct FlyoutClipRow: View {
    let clip: ClipItem
    let isHovered: Bool
    let onPaste: () -> Void
    let onCopy: () -> Void
    let onSave: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Icon
            Image(systemName: contentTypeIcon)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text(clip.preview)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(2)
                
                Text(clip.displayTime)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Hover action button
            if isHovered {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.accentColor.opacity(0.12) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            // Single click = paste immediately (the whole point of a clipboard manager)
            onPaste()
        }
        .contextMenu {
            Button("Copy Only (No Paste)") {
                onCopy()
            }

            Button("Save as Snippet...") {
                onSave()
            }

            Divider()

            Button("Remove from History") {
                onDelete()
            }
        }
    }

    private var contentTypeIcon: String {
        switch clip.contentType {
        case .text: return "doc.text"
        case .url: return "link"
        case .email: return "envelope"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .unknown: return "doc.questionmark"
        }
    }
}

// MARK: - Preview

#Preview {
    RecentClipsColumn(
        searchText: "",
        onSaveAsSnippet: { _ in }
    )
    .environmentObject(ClipboardManager())
    .frame(width: 300, height: 400)
}


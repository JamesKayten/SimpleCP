//
//  SaveSnippetWindowManager.swift
//  SimpleCP
//
//  Window manager for Save Snippet dialog to avoid MenuBarExtra event issues
//  Components: AppKitTextField.swift

import SwiftUI
import AppKit

class SaveSnippetWindowManager: ObservableObject {
    static let shared = SaveSnippetWindowManager()
    private var dialogWindow: NSWindow?

    func showDialog(content: String, clipboardManager: ClipboardManager, onDismiss: @escaping () -> Void) {
        closeDialog()

        let wasAccessory = NSApp.activationPolicy() == .accessory
        let needsTemporaryPromotion = wasAccessory && !UserDefaults.standard.bool(forKey: "showInDock")

        if needsTemporaryPromotion { NSApp.setActivationPolicy(.regular) }

        let dialogView = SaveSnippetDialogContent(
            content: content,
            onDismiss: {
                if needsTemporaryPromotion { NSApp.setActivationPolicy(.accessory) }
                self.closeDialog()
                onDismiss()
            }
        )
        .environmentObject(clipboardManager)
        .frame(width: 400, height: 500)

        let hostingView = NSHostingView(rootView: dialogView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 500)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable, .resizable, .utilityWindow],
            backing: .buffered, defer: false
        )
        panel.title = "Save as Snippet"
        panel.contentView = hostingView
        panel.center()
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.hidesOnDeactivate = false

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        self.dialogWindow = panel
    }

    func closeDialog() {
        dialogWindow?.close()
        dialogWindow = nil
    }
}

struct SaveSnippetDialogContent: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    let content: String
    let onDismiss: () -> Void

    @State private var snippetName = ""
    @State private var selectedFolderId: UUID?
    @State private var createNewFolder = false
    @State private var newFolderName = ""
    @State private var tags = ""
    @State private var contentPreview = ""
    @State private var folderListRefreshID = UUID()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()
            contentPreviewSection
            nameSection
            folderSection
            newFolderToggle
            if createNewFolder { newFolderInput }
            tagsSection
            Spacer()
            Divider()
            actionButtons
        }
        .padding(16)
        .onAppear {
            contentPreview = content
            snippetName = clipboardManager.suggestSnippetName(for: content)
            if selectedFolderId == nil { selectedFolderId = clipboardManager.folders.first?.id }
        }
    }

    private var header: some View {
        HStack {
            Text("Save as Snippet").font(.headline)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
            }.buttonStyle(.plain)
        }
    }

    private var contentPreviewSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Content Preview:").font(.caption).foregroundColor(.secondary)
            Text(contentPreview)
                .font(.system(size: 10, design: .monospaced))
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(4)
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Snippet Name:").font(.caption)
            AppKitTextField(text: $snippetName, placeholder: "Name", onCommit: {
                if !snippetName.isEmpty { saveSnippet() }
            }).frame(height: 22)
        }
    }

    private var folderSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Folder:").font(.caption)
            ScrollView {
                VStack(spacing: 2) {
                    folderRow(label: "None", folderId: nil)
                    ForEach(clipboardManager.folders, id: \.id) { folder in
                        folderRow(label: "\(folder.icon) \(folder.name)", folderId: folder.id).id(folder.id)
                    }
                }.id(folderListRefreshID)
            }
            .frame(height: 80)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(4)
        }
    }

    private var newFolderToggle: some View {
        Button(action: { createNewFolder.toggle() }) {
            HStack(spacing: 6) {
                Image(systemName: createNewFolder ? "checkmark.square.fill" : "square")
                    .foregroundColor(createNewFolder ? .blue : .secondary)
                Text("Create new folder").font(.caption).foregroundColor(createNewFolder ? .blue : .primary)
            }
        }.buttonStyle(.plain)
    }

    private var newFolderInput: some View {
        HStack(spacing: 8) {
            AppKitTextField(text: $newFolderName, placeholder: "Folder name", onCommit: createFolder).frame(height: 22)
            Button(action: { if !newFolderName.isEmpty { createFolder() } }) {
                Image(systemName: "plus.circle.fill").font(.system(size: 20))
                    .foregroundColor(newFolderName.isEmpty ? .gray : .blue)
            }.buttonStyle(.borderless)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3)).cornerRadius(4)
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Tags:").font(.caption).foregroundColor(.secondary)
            AppKitTextField(text: $tags, placeholder: "#tag1 #tag2").frame(height: 22)
        }
    }

    private var actionButtons: some View {
        HStack {
            Spacer()
            Button("Cancel") { onDismiss() }.keyboardShortcut(.cancelAction)
            Button("Save") { saveSnippet() }
                .keyboardShortcut(.defaultAction)
                .disabled(snippetName.isEmpty || content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func folderRow(label: String, folderId: UUID?) -> some View {
        Button(action: { selectedFolderId = folderId }) {
            HStack {
                Circle().fill(selectedFolderId == folderId ? Color.blue : Color.clear).frame(width: 6, height: 6)
                Text(label).font(.caption)
                Spacer()
            }
            .padding(4)
            .background(selectedFolderId == folderId ? Color.blue.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    private func createFolder() {
        guard !newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let trimmedName = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        let newFolderId = clipboardManager.createFolder(name: trimmedName)

        DispatchQueue.main.async {
            self.folderListRefreshID = UUID()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeInOut(duration: 0.2)) { self.selectedFolderId = newFolderId }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.createNewFolder = false
                    self.newFolderName = ""
                }
            }
        }
    }

    private func saveSnippet() {
        guard !snippetName.isEmpty, !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let tagArray = tags.components(separatedBy: CharacterSet(charactersIn: "#, "))
            .map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }

        clipboardManager.saveAsSnippet(name: snippetName, content: content, folderId: selectedFolderId, tags: tagArray)
        onDismiss()
    }
}

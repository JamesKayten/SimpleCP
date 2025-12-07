//
//  ContentView+ControlBar.swift
//  SimpleCP
//
//  Control bar and action methods extension for ContentView
//

import SwiftUI

extension ContentView {
    // MARK: - Control Bar

    var controlBar: some View {
        HStack(spacing: 12) {
            // Show install dependencies button if backend is not running
            if !backendService.isRunning {
                Button(action: {
                    installDependencies()
                }) {
                    Label("Install Dependencies", systemImage: "arrow.down.circle")
                        .font(.system(size: 11))
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .help("Install Python dependencies (may take 30-60 seconds)")
            }
            
            // Show force kill port button if there's a port error
            if let error = backendService.backendError, error.contains("port") || error.contains("Port") {
                Button(action: {
                    forceKillPort()
                }) {
                    Label("Force Kill Port", systemImage: "exclamationmark.triangle")
                        .font(.system(size: 11))
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .help("Kill process using port \(backendService.port)")
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }

    // MARK: - Actions
    
    func forceKillPort() {
        Task {
            print("🔴 Force killing process on port \(backendService.port)...")
            
            await MainActor.run {
                let killed = backendService.killProcessOnPort(backendService.port)
                
                if killed {
                    print("✅ Port \(backendService.port) freed")
                    // Wait a moment, then restart backend
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.backendService.restartBackend()
                    }
                } else {
                    print("❌ Failed to kill process on port \(backendService.port)")
                    print("💡 Try manually in Terminal: lsof -ti:\(backendService.port) | xargs kill -9")
                }
            }
        }
    }
    
    func installDependencies() {
        Task {
            print("🔄 Manually installing Python dependencies...")
            let success = await backendService.installDependenciesManually()
            
            if success {
                print("✅ Dependencies installed, restarting backend...")
                // Wait a moment, then restart backend
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    backendService.restartBackend()
                }
            } else {
                print("❌ Failed to install dependencies")
            }
        }
    }

    func clearHistory() {
        let alert = NSAlert()
        alert.messageText = "Clear History"
        alert.informativeText = "Are you sure you want to clear all clipboard history?"
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        // Ensure alert appears in front of all windows
        if let window = NSApp.keyWindow ?? NSApp.windows.first {
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn {
                    clipboardManager.clearHistory()
                }
            }
        } else {
            // Fallback if no window is available
            if alert.runModal() == .alertFirstButtonReturn {
                clipboardManager.clearHistory()
            }
        }
    }

    func createAutoNamedFolder() {
        // Generate a unique folder name
        var folderNumber = 1
        var proposedName = "Folder \(folderNumber)"

        // Find the next available folder name
        while clipboardManager.folders.contains(where: { $0.name == proposedName }) {
            folderNumber += 1
            proposedName = "Folder \(folderNumber)"
        }

        // Create the folder immediately without any dialog
        _ = clipboardManager.createFolder(name: proposedName)
        print("✅ Auto-created folder: \(proposedName)")
    }

    func deleteEmptyFolders() {
        let emptyFolders = clipboardManager.folders.filter { folder in
            clipboardManager.getSnippets(for: folder.id).isEmpty
        }

        for folder in emptyFolders {
            clipboardManager.deleteFolder(folder)
        }
    }

    func exportSnippets() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "SimpleCP-Snippets.json"

        if panel.runModal() == .OK, let url = panel.url {
            let data = ExportData(
                snippets: clipboardManager.snippets,
                folders: clipboardManager.folders
            )

            if let encoded = try? JSONEncoder().encode(data) {
                try? encoded.write(to: url)
            }
        }
    }

    func importSnippets() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            if let data = try? Data(contentsOf: url),
               let decoded = try? JSONDecoder().decode(ExportData.self, from: data) {
                // Merge imported data
                for folder in decoded.folders {
                    if !clipboardManager.folders.contains(where: { $0.id == folder.id }) {
                        clipboardManager.folders.append(folder)
                    }
                }
                for snippet in decoded.snippets {
                    if !clipboardManager.snippets.contains(where: { $0.id == snippet.id }) {
                        clipboardManager.snippets.append(snippet)
                    }
                }
            }
        }
    }
}

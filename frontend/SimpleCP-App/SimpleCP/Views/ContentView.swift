//
//  ContentView.swift
//  SimpleCP
//
//  Created by SimpleCP
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @EnvironmentObject var backendService: BackendService
    @Environment(\.openWindow) private var openWindow
    @State private var searchText = ""
    @State private var selectedClipForSave: ClipItem?
    @State private var selectedFolderId: UUID?

    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                // Header Bar
                headerBar

                // Search Bar
                searchBar

                // Control Bar
                controlBar

                Divider()

                // Two-Column Layout
                HSplitView {
                    // Left Column: Recent Clips
                    RecentClipsColumn(
                        searchText: searchText,
                        onSaveAsSnippet: { clip in
                            selectedClipForSave = clip
                            SaveSnippetWindowManager.shared.showDialog(
                                content: clip.content,
                                clipboardManager: clipboardManager,
                                onDismiss: {
                                    selectedClipForSave = nil
                                }
                            )
                        }
                    )
                    .frame(minWidth: 250, idealWidth: 300)

                    // Right Column: Saved Snippets
                    SavedSnippetsColumn(searchText: searchText, selectedFolderId: $selectedFolderId)
                        .frame(minWidth: 250, idealWidth: 300)
                }
            }
        }
        // Error alert for clipboard manager errors
        .alert("Error", isPresented: $clipboardManager.showError, presenting: clipboardManager.lastError) { error in
            Button("OK", role: .cancel) {
                clipboardManager.lastError = nil
            }
        } message: { error in
            VStack(alignment: .leading, spacing: 8) {
                if let description = error.errorDescription {
                    Text(description)
                }
                if let recovery = error.recoverySuggestion {
                    Text("\n\(recovery)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            HStack(spacing: 8) {
                Text("SimpleCP")
                    .font(.headline)
                    .foregroundColor(.primary)

                // Connection Status Indicator
                connectionStatusIndicator
            }

            Spacer()

            Button(action: {
                openSettingsWindow()
            }) {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Settings")

            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Quit")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search clips and snippets...", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
    
    // MARK: - Settings
    
    private func openSettingsWindow() {
        // Direct AppKit approach to open settings window
        for window in NSApp.windows {
            if window.title == "Settings" {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }
        }
        
        // If window doesn't exist, try SwiftUI approach
        openWindow(id: "settings")
        
        // Give it a moment, then activate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(ClipboardManager())
        .frame(width: 600, height: 400)
}

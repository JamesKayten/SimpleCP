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
    @State private var isSearching = false
    @State private var selectedClipForSave: ClipItem?
    @State private var selectedFolderId: UUID?
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        ZStack {
            // Solid background to override popover transparency and prevent visual artifacts
            Color(NSColor.windowBackgroundColor)
                .opacity(1.0) // Ensure completely opaque background
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
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
                    .frame(minWidth: 200, maxWidth: .infinity)

                    // Right Column: Saved Snippets
                    SavedSnippetsColumn(searchText: searchText, selectedFolderId: $selectedFolderId)
                        .frame(minWidth: 200, maxWidth: .infinity)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 3.0))
        .clipped() // Prevent content from overflowing
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

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 14))

            TextField("Search clips and snippets...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isSearchFieldFocused)
                .onChange(of: isSearchFieldFocused) { focused in
                    if focused {
                        // Make the window key so it can receive keyboard input
                        MenuBarManager.shared.makeWindowKey()
                    }
                }

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
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(NSColor.textBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            isSearchFieldFocused = true
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(ClipboardManager())
        .environmentObject(BackendService())
        .frame(width: 600, height: 400)
}

#Preview {
    ContentView()
        .environmentObject(ClipboardManager())
        .frame(width: 600, height: 400)
}

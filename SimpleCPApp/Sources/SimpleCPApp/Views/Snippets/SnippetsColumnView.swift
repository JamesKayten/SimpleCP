//
//  SnippetsColumnView.swift
//  SimpleCPApp
//
//  Right column showing snippet folders
//

import SwiftUI

struct SnippetsColumnView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("📁 SAVED SNIPPETS")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding()

            Divider()

            // Content
            if appState.snippetFolders.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No Snippets Yet")
                        .font(.title3)
                        .foregroundColor(.secondary)

                    Text("Save clipboard items as snippets to organize them")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(appState.snippetFolders) { folder in
                            SnippetFolderView(folder: folder)
                        }
                    }
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

#Preview {
    SnippetsColumnView()
        .environmentObject(AppState())
        .frame(width: 400, height: 600)
}

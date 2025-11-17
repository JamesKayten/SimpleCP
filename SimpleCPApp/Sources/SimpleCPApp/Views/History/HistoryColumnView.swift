//
//  HistoryColumnView.swift
//  SimpleCPApp
//
//  Left column showing recent clipboard history
//

import SwiftUI

struct HistoryColumnView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("📋 RECENT CLIPS")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding()

            Divider()

            // Content
            ScrollView {
                LazyVStack(spacing: 1) {
                    // Recent items (1-10)
                    ForEach(Array(appState.historyItems.enumerated()), id: \.element.id) { index, item in
                        HistoryItemView(item: item, index: index + 1)
                    }

                    if !appState.historyItems.isEmpty && !appState.historyFolders.isEmpty {
                        Divider()
                            .padding(.vertical, 8)
                    }

                    // Auto-generated folders (11-20, 21-30, etc.)
                    ForEach(appState.historyFolders) { folder in
                        HistoryFolderView(folder: folder)
                    }
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

#Preview {
    HistoryColumnView()
        .environmentObject(AppState())
        .frame(width: 400, height: 600)
}

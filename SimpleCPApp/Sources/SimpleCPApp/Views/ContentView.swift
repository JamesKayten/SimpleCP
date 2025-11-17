//
//  ContentView.swift
//  SimpleCPApp
//
//  Main window with header and two-column layout
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingSaveSnippetDialog = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with title
            HeaderView(onSaveSnippet: {
                showingSaveSnippetDialog = true
            })

            // Search bar
            SearchBarView()

            // Control bar
            ControlBarView(onSaveSnippet: {
                showingSaveSnippetDialog = true
            })

            Divider()

            // Two-column layout
            HSplitView {
                // Left column: History
                HistoryColumnView()
                    .frame(minWidth: 300)

                // Right column: Snippets
                SnippetsColumnView()
                    .frame(minWidth: 300)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Status bar
            if let error = appState.errorMessage {
                StatusBarView(message: error, isError: true)
            }
        }
        .sheet(isPresented: $showingSaveSnippetDialog) {
            SaveSnippetDialog()
                .environmentObject(appState)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .frame(width: 900, height: 700)
}

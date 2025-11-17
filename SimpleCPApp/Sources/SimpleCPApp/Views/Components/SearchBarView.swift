//
//  SearchBarView.swift
//  SimpleCPApp
//
//  Global search bar for clips and snippets
//

import SwiftUI

struct SearchBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search clips and snippets...", text: $appState.searchQuery)
                .textFieldStyle(.plain)
                .onChange(of: appState.searchQuery) { _, newValue in
                    Task {
                        await appState.performSearch()
                    }
                }

            if !appState.searchQuery.isEmpty {
                Button(action: {
                    appState.searchQuery = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

#Preview {
    SearchBarView()
        .environmentObject(AppState())
}

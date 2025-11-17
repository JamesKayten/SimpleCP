//
//  ControlBarView.swift
//  SimpleCPApp
//
//  Control bar with snippet and folder management actions
//

import SwiftUI

struct ControlBarView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingCreateFolderDialog = false
    @State private var newFolderName = ""

    let onSaveSnippet: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onSaveSnippet) {
                Label("Save as Snippet", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)

            Button(action: {
                showingCreateFolderDialog = true
            }) {
                Label("Create Folder", systemImage: "folder.badge.plus")
            }

            Button(action: {
                Task {
                    await appState.clearHistory()
                }
            }) {
                Label("Clear History", systemImage: "trash")
            }

            Spacer()

            if appState.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .alert("Create Folder", isPresented: $showingCreateFolderDialog) {
            TextField("Folder Name", text: $newFolderName)
            Button("Cancel", role: .cancel) {
                newFolderName = ""
            }
            Button("Create") {
                Task {
                    await appState.createFolder(name: newFolderName)
                    newFolderName = ""
                }
            }
        } message: {
            Text("Enter a name for the new snippet folder")
        }
    }
}

#Preview {
    ControlBarView(onSaveSnippet: {})
        .environmentObject(AppState())
}

//
//  ContentViewSheets.swift
//  SimpleCP
//
//  Sheet components and models for ContentView
//

import SwiftUI

// MARK: - Create Folder Sheet

struct CreateFolderSheet: View {
    @Binding var isPresented: Bool
    @Binding var folderName: String
    let clipboardManager: ClipboardManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Create New Folder")
                    .font(.headline)
                Spacer()
                Button(action: {
                    print("Folder dialog close button clicked")
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Folder Name Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Folder Name:")
                    .font(.subheadline)

                TextField("Enter folder name", text: $folderName)
                    .textFieldStyle(.roundedBorder)
            }

            Divider()

            // Action Buttons
            HStack {
                Spacer()

                Button("Cancel") {
                    print("Folder creation cancelled")
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Create Folder") {
                    print("Creating folder with name: '\(folderName)'")
                    if !folderName.isEmpty {
                        _ = clipboardManager.createFolder(name: folderName)
                        print("✅ Folder created: \(folderName)")
                        isPresented = false
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(folderName.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
}

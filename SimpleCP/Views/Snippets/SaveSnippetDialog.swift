import SwiftUI

// Complete snippet save workflow dialog
struct SaveSnippetDialog: View {
    let item: ClipboardItem
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var apiClient: APIClient
    @State private var snippetService: SnippetService?

    @State private var snippetName = ""
    @State private var selectedFolder = ""
    @State private var showNewFolder = false
    @State private var newFolderName = ""
    @State private var tagsString = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Save as Snippet")
                .font(.title2)
                .fontWeight(.bold)

            // Content preview
            GroupBox(label: Text("Content Preview")) {
                ScrollView {
                    Text(item.content)
                        .textSelection(.enabled)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 120)
            }

            // Snippet name field
            VStack(alignment: .leading, spacing: 4) {
                Text("Snippet Name")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("Enter snippet name", text: $snippetName)
                    .textFieldStyle(.roundedBorder)
            }

            // Folder selection
            VStack(alignment: .leading, spacing: 4) {
                Text("Folder")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if showNewFolder {
                    HStack {
                        TextField("New folder name", text: $newFolderName)
                            .textFieldStyle(.roundedBorder)

                        Button("Cancel") {
                            showNewFolder = false
                            newFolderName = ""
                        }
                    }
                } else {
                    HStack {
                        Picker("", selection: $selectedFolder) {
                            if appState.snippetFolderNames.isEmpty {
                                Text("No folders available").tag("")
                            } else {
                                ForEach(appState.snippetFolderNames, id: \.self) { folder in
                                    Text(folder).tag(folder)
                                }
                            }
                        }
                        .labelsHidden()

                        Button("New Folder") {
                            showNewFolder = true
                        }
                    }
                }
            }

            // Tags field
            VStack(alignment: .leading, spacing: 4) {
                Text("Tags (comma-separated, optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("e.g., code, swift, example", text: $tagsString)
                    .textFieldStyle(.roundedBorder)
            }

            Spacer()

            // Action buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }

                Spacer()

                Button("Save Snippet") {
                    Task {
                        await saveSnippet()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
        }
        .padding()
        .frame(width: 500, height: 500)
        .onAppear {
            snippetService = SnippetService(apiClient: apiClient, appState: appState)
            snippetName = StringUtils.suggestSnippetName(from: item.content)

            if !appState.snippetFolderNames.isEmpty {
                selectedFolder = appState.snippetFolderNames.first ?? ""
            }
        }
    }

    private var isValid: Bool {
        !snippetName.isEmpty && (!selectedFolder.isEmpty || !newFolderName.isEmpty)
    }

    private func saveSnippet() async {
        guard let service = snippetService else { return }

        // Create new folder if needed
        if showNewFolder && !newFolderName.isEmpty {
            await service.createFolder(name: newFolderName)
            selectedFolder = newFolderName
        }

        // Parse tags
        let tags = StringUtils.parseTags(tagsString)

        // Create snippet
        await service.createSnippet(
            content: item.content,
            name: snippetName,
            folder: selectedFolder,
            tags: tags
        )

        dismiss()
    }
}

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Combined Search and Control Bar
            HStack(spacing: 12) {
                // Search field with icon
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search clips and snippets...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)

                Spacer()

                // Control buttons
                Button(action: { appState.showCreateSnippet = true }) {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.plain)
                .help("Create Snippet")

                Button(action: { appState.showManageFolders = true }) {
                    Image(systemName: "folder.fill")
                }
                .buttonStyle(.plain)
                .help("Manage Folders")

                Button(action: { appState.showClearHistory = true }) {
                    Image(systemName: "doc.on.clipboard.fill")
                }
                .buttonStyle(.plain)
                .help("Clear History")

                Button(action: { appState.showSettings = true }) {
                    Image(systemName: "gearshape.fill")
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Two-Column Layout
            HStack(spacing: 0) {
                // Left Column: Recent Clips
                RecentClipsColumn(searchText: searchText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()

                // Right Column: Saved Snippets
                SavedSnippetsColumn(searchText: searchText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}

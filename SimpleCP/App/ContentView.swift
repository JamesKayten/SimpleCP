import SwiftUI

// Main window container with two-column layout
struct ContentView: View {
    @EnvironmentObject var apiClient: APIClient
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Header with search and settings
            HeaderView()

            Divider()

            // Control bar with actions
            ControlBar()

            Divider()

            // Two-column layout
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Left column: History
                    HistoryColumnView()
                        .frame(width: geometry.size.width / 2)

                    Divider()

                    // Right column: Snippets
                    SnippetsColumnView()
                        .frame(width: geometry.size.width / 2)
                }
            }
        }
        .sheet(isPresented: $appState.showingSaveSnippetDialog) {
            if let item = appState.itemToSave {
                SaveSnippetDialog(item: item)
                    .environmentObject(apiClient)
                    .environmentObject(appState)
            }
        }
        .alert("Error", isPresented: .constant(appState.errorMessage != nil)) {
            Button("OK") {
                appState.errorMessage = nil
            }
        } message: {
            if let error = appState.errorMessage {
                Text(error)
            }
        }
    }
}

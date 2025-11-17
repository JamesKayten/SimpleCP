import SwiftUI

// Control bar with save snippet and manage buttons
struct ControlBar: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var apiClient: APIClient
    @State private var clipboardService: ClipboardService?

    var body: some View {
        HStack {
            Button(action: {
                if let item = appState.selectedHistoryItem {
                    appState.showSaveDialog(for: item)
                }
            }) {
                Label("Save as Snippet", systemImage: "square.and.arrow.down")
            }
            .disabled(appState.selectedHistoryItem == nil)

            Spacer()

            Button(action: {
                Task {
                    if let service = clipboardService {
                        await service.clearHistory()
                    }
                }
            }) {
                Label("Clear History", systemImage: "trash")
            }

            Button(action: {
                Task {
                    if let service = clipboardService {
                        await service.refresh()
                    }
                }
            }) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            clipboardService = ClipboardService(apiClient: apiClient, appState: appState)
        }
    }
}

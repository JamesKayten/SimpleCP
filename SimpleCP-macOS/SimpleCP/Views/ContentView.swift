import SwiftUI

struct ContentView: View {
    @StateObject private var clipboardService = ClipboardService()
    @State private var selectedTab = 0

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $selectedTab) {
                NavigationLink(value: 0) {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                NavigationLink(value: 1) {
                    Label("Snippets", systemImage: "square.and.pencil")
                }
                NavigationLink(value: 2) {
                    Label("Settings", systemImage: "gear")
                }
            }
            .navigationSplitViewColumnWidth(200)
            .toolbar {
                ToolbarItem {
                    Button(action: refreshData) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        } detail: {
            // Main content
            Group {
                switch selectedTab {
                case 0:
                    HistoryView()
                case 1:
                    SnippetsView()
                case 2:
                    SettingsView()
                default:
                    HistoryView()
                }
            }
            .environmentObject(clipboardService)
        }
        .onAppear {
            refreshData()
        }
    }

    private func refreshData() {
        Task {
            await clipboardService.fetchHistory()
            await clipboardService.fetchSnippets()
        }
    }
}

#Preview {
    ContentView()
}
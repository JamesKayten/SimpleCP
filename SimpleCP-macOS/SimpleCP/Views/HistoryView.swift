import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var clipboardService: ClipboardService
    @State private var searchText = ""

    var body: some View {
        VStack {
            // Search bar
            SearchBar(text: $searchText)
                .padding()

            // History list
            List(clipboardService.historyItems) { item in
                HistoryItemRow(item: item)
                    .onTapGesture {
                        Task {
                            await clipboardService.copyItem(item)
                        }
                    }
                    .contextMenu {
                        Button("Copy") {
                            Task {
                                await clipboardService.copyItem(item)
                            }
                        }
                        Button("Save as Snippet") {
                            // TODO: Show save snippet dialog
                        }
                    }
            }
            .refreshable {
                await clipboardService.fetchHistory()
            }
        }
        .navigationTitle("Clipboard History")
        .toolbar {
            ToolbarItem {
                Button("Clear All") {
                    // TODO: Confirm and clear history
                }
            }
        }
    }
}

struct HistoryItemRow: View {
    let item: ClipboardItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.preview)
                .lineLimit(2)
                .font(.body)

            HStack {
                Text("\(item.charCount) chars")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(formatDate(item.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func formatDate(_ timestamp: String) -> String {
        // TODO: Implement proper date formatting
        return timestamp
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search clipboard...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            if !text.isEmpty {
                Button("Clear") {
                    text = ""
                }
                .foregroundColor(.secondary)
            }
        }
    }
}

struct MenuBarView: View {
    var body: some View {
        VStack {
            Text("SimpleCP")
                .font(.headline)

            Divider()

            Button("Show Main Window") {
                // TODO: Show main window
            }

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
    }
}

#Preview {
    HistoryView()
        .environmentObject(ClipboardService())
}
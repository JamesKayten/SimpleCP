import SwiftUI

struct QuickAccessView: View {
    let apiClient: SimpleCPAPIClient
    @State private var recentItems: [ClipboardItem] = []
    @State private var searchText: String = ""
    @State private var isLoading: Bool = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Quick Access")
                    .font(.headline)
                Spacer()
                Button(action: refresh) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
            }
            .padding()

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search clipboard...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onChange(of: searchText) { _ in
                        performSearch()
                    }

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)

            Divider()

            // Items list
            if isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if let error = error {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text(error)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else if recentItems.isEmpty {
                VStack {
                    Image(systemName: "doc.on.clipboard")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No clipboard history")
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(Array(recentItems.enumerated()), id: \.element.id) { index, item in
                            ClipboardItemRow(item: item, index: index + 1)
                                .onTapGesture {
                                    copyItem(item)
                                }
                                .contextMenu {
                                    Button("Copy") {
                                        copyItem(item)
                                    }
                                    Button("Delete", role: .destructive) {
                                        deleteItem(item)
                                    }
                                }
                        }
                    }
                }
            }
        }
        .frame(width: 400, height: 500)
        .onAppear {
            loadRecentItems()
        }
    }

    func loadRecentItems() {
        isLoading = true
        error = nil

        Task {
            do {
                let items = try await apiClient.getRecentHistory()
                await MainActor.run {
                    recentItems = items
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to load clipboard history"
                    isLoading = false
                }
            }
        }
    }

    func refresh() {
        loadRecentItems()
    }

    func performSearch() {
        guard !searchText.isEmpty else {
            loadRecentItems()
            return
        }

        isLoading = true
        error = nil

        Task {
            do {
                let results = try await apiClient.search(query: searchText)
                await MainActor.run {
                    recentItems = results.history + results.snippets
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = "Search failed"
                    isLoading = false
                }
            }
        }
    }

    func copyItem(_ item: ClipboardItem) {
        Task {
            do {
                try await apiClient.copyToClipboard(clipId: item.clipId)
                // Close popover after copy
                NSApplication.shared.keyWindow?.close()
            } catch {
                print("Failed to copy item: \(error)")
            }
        }
    }

    func deleteItem(_ item: ClipboardItem) {
        Task {
            do {
                try await apiClient.deleteHistoryItem(clipId: item.clipId)
                await MainActor.run {
                    recentItems.removeAll { $0.id == item.id }
                }
            } catch {
                print("Failed to delete item: \(error)")
            }
        }
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let index: Int

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Index number
            Text("\(index)")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 20, alignment: .trailing)

            // Content preview
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayString)
                    .lineLimit(2)
                    .font(.system(.body))

                HStack(spacing: 8) {
                    // Content type badge
                    Text(item.contentType.uppercased())
                        .font(.system(.caption2))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(typeColor(item.contentType).opacity(0.2))
                        .foregroundColor(typeColor(item.contentType))
                        .cornerRadius(4)

                    // Source app
                    if let sourceApp = item.sourceApp {
                        Text(sourceApp)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Timestamp
                    Text(formatTimestamp(item.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
    }

    func typeColor(_ type: String) -> Color {
        switch type {
        case "url": return .blue
        case "email": return .green
        case "code": return .purple
        default: return .gray
        }
    }

    func formatTimestamp(_ timestamp: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: timestamp) else {
            return timestamp
        }

        let now = Date()
        let diff = now.timeIntervalSince(date)

        if diff < 60 {
            return "just now"
        } else if diff < 3600 {
            let mins = Int(diff / 60)
            return "\(mins)m ago"
        } else if diff < 86400 {
            let hours = Int(diff / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(diff / 86400)
            return "\(days)d ago"
        }
    }
}

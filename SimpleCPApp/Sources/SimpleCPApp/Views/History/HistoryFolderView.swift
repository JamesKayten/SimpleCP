//
//  HistoryFolderView.swift
//  SimpleCPApp
//
//  Auto-generated history folder (11-20, 21-30, etc.)
//

import SwiftUI

struct HistoryFolderView: View {
    @EnvironmentObject var appState: AppState
    let folder: HistoryFolder

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Folder header
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: isExpanded ? "folder.fill" : "folder")
                        .foregroundColor(.secondary)

                    Text(folder.name)
                        .font(.headline)

                    Text("(\(folder.count))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(Color(NSColor.controlBackgroundColor))

            // Folder contents (when expanded)
            if isExpanded {
                ForEach(Array(folder.items.enumerated()), id: \.element.id) { offset, item in
                    HistoryItemView(
                        item: item,
                        index: folder.startIndex + offset + 1
                    )
                    .padding(.leading, 20)
                }
            }
        }
    }
}

#Preview {
    HistoryFolderView(
        folder: HistoryFolder(
            name: "11-20",
            startIndex: 10,
            endIndex: 19,
            count: 10,
            items: []
        )
    )
    .environmentObject(AppState())
    .frame(width: 400)
}

import SwiftUI

// Auto-generated history folder (e.g., "11-20")
struct HistoryFolderView: View {
    let folder: HistoryFolder
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Folder header
            Button(action: {
                isExpanded.toggle()
            }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)

                    Image(systemName: "folder")
                        .foregroundColor(.secondary)

                    Text(folder.name)
                        .font(.body)

                    Spacer()

                    Text("\(folder.itemCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
            )

            // Expanded content (placeholder for now)
            if isExpanded {
                Text("Items \(folder.startIndex)-\(folder.endIndex)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 32)
                    .padding(.vertical, 4)
            }
        }
        .padding(.horizontal)
    }
}

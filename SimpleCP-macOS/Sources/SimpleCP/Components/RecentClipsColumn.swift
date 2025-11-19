//
//  RecentClipsColumn.swift
//  SimpleCP
//
//  Created by SimpleCP
//

import SwiftUI

struct RecentClipsColumn: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    let searchText: String
    let onSaveAsSnippet: (ClipItem) -> Void

    @State private var hoveredClipId: UUID?
    @State private var selectedClipId: UUID?

    private var filteredClips: [ClipItem] {
        if searchText.isEmpty {
            return clipboardManager.clipHistory
        }
        let (clips, _) = clipboardManager.search(query: searchText)
        return clips
    }

    private var recentClips: [ClipItem] {
        Array(filteredClips.prefix(10))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column Header
            HStack {
                Image(systemName: "doc.on.clipboard")
                    .foregroundColor(.secondary)
                Text("RECENT CLIPS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Clips List
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) {
                    // Recent 10 clips
                    ForEach(Array(recentClips.enumerated()), id: \.element.id) { index, clip in
                        ClipItemRow(
                            index: index + 1,
                            clip: clip,
                            isHovered: hoveredClipId == clip.id,
                            isSelected: selectedClipId == clip.id,
                            onCopy: {
                                clipboardManager.copyToClipboard(clip.content)
                                selectedClipId = clip.id
                            },
                            onSave: {
                                onSaveAsSnippet(clip)
                            },
                            onDelete: {
                                clipboardManager.removeFromHistory(item: clip)
                            }
                        )
                        .onHover { isHovered in
                            hoveredClipId = isHovered ? clip.id : nil
                        }
                        .contextMenu {
                            Button("Copy") {
                                clipboardManager.copyToClipboard(clip.content)
                            }
                            Button("Save as Snippet...") {
                                onSaveAsSnippet(clip)
                            }
                            Divider()
                            Button("Remove from History") {
                                clipboardManager.removeFromHistory(item: clip)
                            }
                        }
                    }

                    // Grouped history folders
                    if filteredClips.count > 10 {
                        Divider()
                            .padding(.vertical, 8)

                        ForEach(historyGroups, id: \.range) { group in
                            HistoryGroupRow(
                                range: group.range,
                                count: group.count
                            )
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - History Groups

    private var historyGroups: [(range: String, count: Int)] {
        var groups: [(String, Int)] = []
        let total = filteredClips.count

        for i in stride(from: 11, to: total + 1, by: 10) {
            let start = i
            let end = min(i + 9, total)
            let count = clipboardManager.clipHistory[safe: start - 1..<end]?.count ?? 0
            if count > 0 {
                groups.append(("\(start) - \(end)", count))
            }
        }

        return groups
    }
}

// MARK: - Clip Item Row

struct ClipItemRow: View {
    let index: Int
    let clip: ClipItem
    let isHovered: Bool
    let isSelected: Bool
    let onCopy: () -> Void
    let onSave: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Index
            Text("\(index).")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 20, alignment: .trailing)

            // Content preview
            VStack(alignment: .leading, spacing: 2) {
                Text(clip.preview)
                    .font(.system(size: 12))
                    .lineLimit(2)
                    .foregroundColor(.primary)

                Text(clip.displayTime)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Actions (shown on hover)
            if isHovered {
                HStack(spacing: 4) {
                    Button(action: onSave) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .help("Save as snippet")

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .help("Remove")
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : (isHovered ? Color(NSColor.controlBackgroundColor) : Color.clear))
        .contentShape(Rectangle())
        .onTapGesture {
            onCopy()
        }
    }
}

// MARK: - History Group Row

struct HistoryGroupRow: View {
    let range: String
    let count: Int

    var body: some View {
        HStack {
            Image(systemName: "folder")
                .foregroundColor(.secondary)
            Text(range)
                .font(.system(size: 12))
            Text("(\(count) clips)")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe range: Range<Index>) -> ArraySlice<Element>? {
        if range.lowerBound >= 0 && range.upperBound <= count {
            return self[range]
        }
        return nil
    }
}

// MARK: - Preview

#Preview {
    RecentClipsColumn(
        searchText: "",
        onSaveAsSnippet: { _ in }
    )
    .environmentObject(ClipboardManager())
    .frame(width: 300, height: 400)
}

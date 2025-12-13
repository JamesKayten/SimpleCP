//
//  SavedSnippetsColumn+SnippetRow.swift
//  SimpleCP
//
//  Snippet row and popover components
//

import SwiftUI

// MARK: - Snippet Item Row

struct SnippetItemRow: View {
    let snippet: Snippet
    let isHovered: Bool
    let onCopy: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showPopover = false
    @State private var hoverTimer: Timer?
    @State private var localHover = false
    @Environment(\.fontPreferences) private var fontPrefs
    @AppStorage("showSnippetPreviews") private var showSnippetPreviews = false

    var body: some View {
        HStack(spacing: 8) {
            if snippet.isFavorite {
                Image(systemName: "star.fill")
                    .font(fontPrefs.interfaceFont())
                    .foregroundColor(.yellow)
                    .fixedSize()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(snippet.name)
                    .font(fontPrefs.clipContentFont())
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if !snippet.tags.isEmpty {
                    Text(snippet.tags.map { "#\($0)" }.joined(separator: " "))
                        .font(fontPrefs.interfaceFont())
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 4)

            if isHovered || localHover {
                HStack(spacing: 4) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil").font(fontPrefs.interfaceFont())
                    }
                    .buttonStyle(.plain)
                    .help("Edit")
                }
                .foregroundColor(.secondary)
                .fixedSize()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill((isHovered || localHover) ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder((isHovered || localHover) ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { onCopy() }
        .popover(isPresented: $showPopover, arrowEdge: .trailing) {
            SnippetContentPopover(snippet: snippet)
        }
        .onContinuousHover { phase in
            switch phase {
            case .active(_):
                localHover = true
                if showSnippetPreviews {
                    hoverTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                        showPopover = true
                    }
                }
            case .ended:
                localHover = false
                hoverTimer?.invalidate()
                hoverTimer = nil
                showPopover = false
            }
        }
    }
}

// MARK: - Snippet Content Popover

struct SnippetContentPopover: View {
    let snippet: Snippet
    @Environment(\.fontPreferences) private var fontPrefs

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if snippet.isFavorite {
                    Image(systemName: "star.fill").foregroundColor(.yellow).font(fontPrefs.interfaceFont())
                }
                Text(snippet.name).font(fontPrefs.interfaceFont(weight: .semibold)).foregroundColor(.primary)
                Spacer()
                Text(snippet.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(fontPrefs.interfaceFont()).foregroundColor(.secondary)
            }

            if !snippet.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(snippet.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(fontPrefs.interfaceFont())
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.7))
                            .cornerRadius(4)
                    }
                }
            }

            Divider()

            ScrollView {
                Text(snippet.content)
                    .font(fontPrefs.clipContentFont())
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: 400, maxHeight: 300)

            HStack {
                Text("\(snippet.content.count) characters").font(fontPrefs.interfaceFont()).foregroundColor(.secondary)
                Spacer()
                if snippet.content.components(separatedBy: .newlines).count > 1 {
                    Text("\(snippet.content.components(separatedBy: .newlines).count) lines")
                        .font(fontPrefs.interfaceFont()).foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .frame(minWidth: 300)
    }
}

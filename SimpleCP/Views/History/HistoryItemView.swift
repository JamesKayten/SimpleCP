import SwiftUI

// Individual history item
struct HistoryItemView: View {
    let item: ClipboardItem
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var apiClient: APIClient
    @State private var clipboardService: ClipboardService?
    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Enhanced content type icon
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 32, height: 32)

                Image(systemName: contentIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                // Professional content text with typography hierarchy
                Text(item.displayString)
                    .lineLimit(3)
                    .font(.system(size: 15, weight: .medium, design: .default))
                    .foregroundColor(Color(red: 0.94, green: 0.94, blue: 0.96))
                    .lineSpacing(2)  // Better line spacing for readability
                    .tracking(0.1)   // Subtle letter spacing for elegance
                    .fixedSize(horizontal: false, vertical: true)

                // Professional metadata with sophisticated typography
                HStack(spacing: 10) {
                    Label(DateUtils.formatRelativeTime(item.timestamp),
                          systemImage: "clock")
                        .font(.system(size: 11, weight: .medium, design: .default))
                        .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.70))
                        .labelStyle(.iconOnly)

                    Text(DateUtils.formatRelativeTime(item.timestamp))
                        .font(.system(size: 11, weight: .medium, design: .default))
                        .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.70))
                        .tracking(0.2)  // Better letter spacing for small text

                    if let sourceApp = item.sourceApp {
                        Text("•")
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.55))
                            .font(.system(size: 10, weight: .regular, design: .default))

                        Text(sourceApp)
                            .font(.system(size: 11, weight: .semibold, design: .default))
                            .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.75))
                            .tracking(0.1)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 8)

            // Modern action buttons
            VStack(spacing: 4) {
                if isHovered {
                    HStack(spacing: 6) {
                        actionButton(icon: "doc.on.clipboard.fill",
                                   color: .blue,
                                   tooltip: "Copy to clipboard") {
                            Task {
                                await clipboardService?.copyToClipboard(item)
                            }
                        }

                        actionButton(icon: "square.and.arrow.down.fill",
                                   color: .green,
                                   tooltip: "Save as snippet") {
                            appState.showSaveDialog(for: item)
                        }

                        actionButton(icon: "trash.fill",
                                   color: .red,
                                   tooltip: "Delete") {
                            Task {
                                await clipboardService?.deleteHistoryItem(item)
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(cardBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(cardBorderColor, lineWidth: isSelected ? 2 : 0.5)
                )
        )
        .shadow(
            color: shadowColor,
            radius: isHovered ? 12 : 6,
            x: 0,
            y: isHovered ? 6 : 3
        )
        .overlay(
            // Inner highlight for depth
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(isHovered ? 0.08 : 0.03),
                            Color.clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                ),
            alignment: .top
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            appState.selectedHistoryItem = item
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .onAppear {
            clipboardService = ClipboardService(apiClient: apiClient, appState: appState)
        }
    }

    private var isSelected: Bool {
        appState.selectedHistoryItem?.clipId == item.clipId
    }

    private var contentIcon: String {
        switch item.contentType {
        case "text":
            return "doc.text.fill"
        case "image":
            return "photo.fill"
        case "url":
            return "link"
        default:
            return "doc.fill"
        }
    }

    private var iconColor: Color {
        switch item.contentType {
        case "text":
            return .blue
        case "image":
            return .green
        case "url":
            return .purple
        default:
            return .gray
        }
    }

    private var iconBackgroundColor: Color {
        iconColor.opacity(0.15)
    }

    private var cardBackgroundColor: Color {
        if isSelected {
            return Color(red: 0.25, green: 0.35, blue: 0.55).opacity(0.3)  // Blue tint for selected in dark theme
        } else if isHovered {
            return Color(red: 0.20, green: 0.20, blue: 0.22)  // Lighter dark for hover
        } else {
            return Color(red: 0.16, green: 0.16, blue: 0.18)  // Card background in dark theme
        }
    }

    private var cardBorderColor: Color {
        if isSelected {
            return Color(red: 0.4, green: 0.7, blue: 1.0)  // Bright blue for selected
        } else if isHovered {
            return Color(red: 0.35, green: 0.35, blue: 0.38).opacity(0.8)
        } else {
            return Color(red: 0.25, green: 0.25, blue: 0.28).opacity(0.5)
        }
    }

    private var shadowColor: Color {
        Color.black.opacity(isSelected ? 0.4 : (isHovered ? 0.25 : 0.15))  // Stronger shadows for dark theme
    }

    private func actionButton(icon: String, color: Color, tooltip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(color)
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .scaleEffect(1.0)
        .onHover { hovering in
            // Add subtle hover effect if needed
        }
    }
}

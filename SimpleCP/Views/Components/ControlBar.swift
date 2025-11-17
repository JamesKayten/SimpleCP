import SwiftUI

// Control bar with save snippet and manage buttons
struct ControlBar: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var apiClient: APIClient
    @State private var clipboardService: ClipboardService?

    var body: some View {
        HStack(spacing: 16) {
            // Dark theme save snippet button
            Button(action: {
                if let item = appState.selectedHistoryItem {
                    appState.showSaveDialog(for: item)
                }
            }) {
                Label("Save as Snippet", systemImage: "square.and.arrow.down.fill")
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .tracking(0.3)
                    .foregroundColor(
                        appState.selectedHistoryItem != nil
                        ? Color(red: 0.4, green: 0.7, blue: 1.0)
                        : Color(red: 0.4, green: 0.4, blue: 0.45)
                    )
            }
            .buttonStyle(.plain)
            .disabled(appState.selectedHistoryItem == nil)

            Spacer()

            HStack(spacing: 12) {
                // Dark theme clear history button
                Button(action: {
                    Task {
                        if let service = clipboardService {
                            await service.clearHistory()
                        }
                    }
                }) {
                    Label("Clear History", systemImage: "trash.fill")
                        .font(.system(size: 13, weight: .medium, design: .default))
                        .tracking(0.2)
                        .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                }
                .buttonStyle(.plain)

                // Dark theme refresh button
                Button(action: {
                    Task {
                        if let service = clipboardService {
                            await service.refresh()
                        }
                    }
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.system(size: 13, weight: .medium, design: .default))
                        .tracking(0.2)
                        .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.75))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            // Dark theme control bar gradient with depth
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.13, green: 0.13, blue: 0.15),
                    Color(red: 0.11, green: 0.11, blue: 0.13),
                    Color(red: 0.09, green: 0.09, blue: 0.11)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            // Sophisticated depth highlights
            VStack(spacing: 0) {
                // Top inner highlight
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.03),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 1)

                Spacer()

                // Bottom subtle shadow
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.black.opacity(0.2)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 2)
            }
        )
        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
        .onAppear {
            clipboardService = ClipboardService(apiClient: apiClient, appState: appState)
        }
    }
}

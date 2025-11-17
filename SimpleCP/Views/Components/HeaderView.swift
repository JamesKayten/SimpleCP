import SwiftUI

// Header with title, search, and settings
struct HeaderView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var apiClient: APIClient
    @State private var clipboardService: ClipboardService?

    var body: some View {
        HStack(spacing: 8) {
            // App title - compact for menu bar
            Text("SimpleCP")
                .font(.system(size: 14, weight: .semibold, design: .default))
                .foregroundColor(Color(red: 0.25, green: 0.50, blue: 1.0))
                .tracking(0.2)
                .frame(width: 70, alignment: .leading)

            // Compact search bar for menu bar app
            SearchBar()
                .frame(maxWidth: .infinity)

            // Settings gear - compact
            Button(action: {
                appState.showingSettings = true
            }) {
                Image(systemName: "gear")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.85))
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .onAppear {
            clipboardService = ClipboardService(apiClient: apiClient, appState: appState)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            // Sophisticated dark header gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.15, green: 0.15, blue: 0.17),     // Rich dark header top
                    Color(red: 0.12, green: 0.12, blue: 0.14),     // Mid transition
                    Color(red: 0.10, green: 0.10, blue: 0.12)      // Darker base
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            // Sophisticated bottom glow with depth
            VStack(spacing: 0) {
                // Top inner highlight
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.04),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 1)

                Spacer()

                // Bottom elegant border with glow
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.3, green: 0.4, blue: 0.6).opacity(0.4),
                        Color(red: 0.25, green: 0.25, blue: 0.28).opacity(0.6),
                        Color(red: 0.20, green: 0.20, blue: 0.23).opacity(0.3),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 3)
            }
        )
        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
    }
}

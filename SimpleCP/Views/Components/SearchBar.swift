import SwiftUI

// Always-visible search bar
struct SearchBar: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var apiClient: APIClient
    @State private var searchService: SearchService?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.65))  // Lighter for dark theme

            TextField("Search your clipboard", text: $appState.searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.92))  // Light text for dark theme
                .onChange(of: appState.searchQuery) { _, newValue in
                    Task {
                        if let service = searchService {
                            await service.search(query: newValue)
                        }
                    }
                }

            if appState.isSearching {
                ProgressView()
                    .scaleEffect(0.6)
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.4, green: 0.7, blue: 1.0)))
            } else if !appState.searchQuery.isEmpty {
                Button(action: {
                    appState.clearSearch()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.55))  // Subtle clear button
                }
                .buttonStyle(.plain)
                .help("Clear search")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    // Dark theme search background with depth
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.18, green: 0.18, blue: 0.20),  // Lighter dark top
                            Color(red: 0.15, green: 0.15, blue: 0.17)   // Deeper dark bottom
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(red: 0.3, green: 0.3, blue: 0.35).opacity(0.6), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 4)
        .overlay(
            // Inner highlight for sophisticated depth
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.06),
                            Color.clear,
                            Color.black.opacity(0.1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .onAppear {
            searchService = SearchService(apiClient: apiClient, appState: appState)
        }
    }
}

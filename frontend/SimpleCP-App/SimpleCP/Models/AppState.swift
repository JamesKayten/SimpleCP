import Foundation
import SwiftUI

// MARK: - App State Management
@MainActor
class AppState: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedHistoryItem: ClipItem?
    @Published var selectedSnippetItem: Snippet?

    var isSearching: Bool {
        !searchQuery.isEmpty
    }

    func clearError() {
        errorMessage = nil
    }

    func setError(_ error: Error) {
        errorMessage = error.localizedDescription
    }

    func clearSearch() {
        searchQuery = ""
    }
}

import SwiftUI

// Main window container for menu bar app
struct ContentView: View {
    @EnvironmentObject var apiClient: APIClient
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Single consolidated header
            HeaderView()

            // Compact tab-based layout for menu bar app
            TabView {
                HistoryColumnView()
                    .tabItem {
                        Image(systemName: "clock")
                        Text("History")
                    }
                    .tag(0)

                SnippetsColumnView()
                    .tabItem {
                        Image(systemName: "doc.text")
                        Text("Snippets")
                    }
                    .tag(1)
            }
            .frame(maxHeight: .infinity)
        }
        .background(
            // Sophisticated dark gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.12, green: 0.12, blue: 0.13),      // Rich dark gray
                    Color(red: 0.08, green: 0.08, blue: 0.09),      // Deeper charcoal
                    Color(red: 0.05, green: 0.05, blue: 0.06)       // Deep dark base
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .preferredColorScheme(.dark)
        .sheet(isPresented: $appState.showingSaveSnippetDialog) {
            if let item = appState.itemToSave {
                SaveSnippetDialog(item: item)
                    .environmentObject(apiClient)
                    .environmentObject(appState)
            }
        }
        .alert("Error", isPresented: .constant(appState.errorMessage != nil)) {
            Button("OK") {
                appState.errorMessage = nil
            }
        } message: {
            if let error = appState.errorMessage {
                Text(error)
            }
        }
    }
}
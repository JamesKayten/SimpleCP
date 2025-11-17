import SwiftUI

// Header with title, search, and settings
struct HeaderView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack {
            Text("SimpleCP")
                .font(.title)
                .fontWeight(.bold)

            Spacer()

            SearchBar()
                .frame(maxWidth: 300)

            Button(action: {
                appState.showingSettings = true
            }) {
                Image(systemName: "gear")
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
}

import SwiftUI

// App entry point
@main
struct SimpleCPApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var apiClient = APIClient()
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(apiClient)
                .environmentObject(appState)
                .frame(
                    minWidth: Constants.windowMinWidth,
                    minHeight: Constants.windowMinHeight
                )
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        Settings {
            SettingsWindow()
                .environmentObject(apiClient)
                .environmentObject(appState)
        }
    }
}

import SwiftUI

// App entry point
@main
struct SimpleCPApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var apiClient = APIClient()
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("SimpleCP", systemImage: "clipboard") {
            ContentView()
                .environmentObject(apiClient)
                .environmentObject(appState)
                .frame(
                    width: Constants.defaultWindowWidth,
                    height: Constants.defaultWindowHeight
                )
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsWindow()
                .environmentObject(apiClient)
                .environmentObject(appState)
        }
    }
}

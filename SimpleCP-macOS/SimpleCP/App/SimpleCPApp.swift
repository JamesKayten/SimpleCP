import SwiftUI

@main
struct SimpleCPApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("SimpleCP", systemImage: "doc.on.clipboard") {
            ContentView()
                .environmentObject(appState)
                .frame(width: 600, height: 400)
        }
        .menuBarExtraStyle(.window)
    }
}

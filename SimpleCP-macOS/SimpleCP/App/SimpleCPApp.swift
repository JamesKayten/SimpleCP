import SwiftUI

@main
struct SimpleCPApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(DefaultWindowStyle())

        MenuBarExtra("SimpleCP", systemImage: "clipboard") {
            MenuBarView()
        }
    }
}
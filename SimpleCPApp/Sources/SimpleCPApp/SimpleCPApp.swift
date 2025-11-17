//
//  SimpleCPApp.swift
//  SimpleCPApp
//
//  Main app entry point
//

import SwiftUI

@main
struct SimpleCPApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 800, minHeight: 600)
                .onAppear {
                    Task {
                        await appState.loadAllData()
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        // Settings window
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

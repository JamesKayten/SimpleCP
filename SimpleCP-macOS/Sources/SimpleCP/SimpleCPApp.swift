//
//  SimpleCPApp.swift
//  SimpleCP
//
//  Created by SimpleCP
//

import SwiftUI

@main
struct SimpleCPApp: App {
    @StateObject private var clipboardManager = ClipboardManager()
    @State private var showSettings = false

    var body: some Scene {
        MenuBarExtra("📋 SimpleCP", systemImage: "doc.on.clipboard") {
            ContentView()
                .environmentObject(clipboardManager)
                .frame(width: 600, height: 400)
        }
        .menuBarExtraStyle(.window)

        // Settings window
        Window("Settings", id: "settings") {
            SettingsWindow()
                .environmentObject(clipboardManager)
                .frame(width: 500, height: 400)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

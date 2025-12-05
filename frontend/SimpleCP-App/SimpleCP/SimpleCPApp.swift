//
//  SimpleCPApp.swift
//  SimpleCP
//
//  Created by SimpleCP
//

import SwiftUI
import ApplicationServices

@main
struct SimpleCPApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var clipboardManager = ClipboardManager()
    @StateObject private var backendService = BackendService()
    @State private var showSettings = false
    @AppStorage("windowSize") private var windowSize = "normal"
    @AppStorage("theme") private var theme = "auto"
    
    // Font preferences
    @AppStorage("interfaceFont") private var interfaceFont = "SF Pro"
    @AppStorage("interfaceFontSize") private var interfaceFontSize = 13.0
    @AppStorage("clipFont") private var clipFont = "SF Mono"
    @AppStorage("clipFontSize") private var clipFontSize = 12.0

    init() {
        // Note: Can't access @StateObject in init
        // The backendService will be shared via AppDelegate after first body evaluation
        
        // Request accessibility permissions on launch (with prompt)
        checkAccessibilityPermissions()
    }
    
    private func checkAccessibilityPermissions() {
        // Create options dictionary to show system prompt
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        
        if !trusted {
            print("⚠️ Accessibility permissions required for 'Paste Immediately' feature")
            print("A system prompt should appear. If not, go to:")
            print("System Settings > Privacy & Security > Accessibility")
        } else {
            print("✅ Accessibility permissions granted")
        }
    }
    
    // MARK: - Window Size Calculation
    
    private var windowDimensions: (width: CGFloat, height: CGFloat) {
        switch windowSize {
        case "compact":
            return (500, 350)
        case "normal":
            return (600, 400)
        case "large":
            return (800, 550)
        default:
            return (600, 400) // fallback to normal
        }
    }
    
    // MARK: - Font Preferences
    
    private var fontPreferences: FontPreferences {
        FontPreferences(
            interfaceFont: interfaceFont,
            interfaceFontSize: interfaceFontSize,
            clipFont: clipFont,
            clipFontSize: clipFontSize
        )
    }
    
    // MARK: - Theme/Color Scheme
    
    private var colorScheme: ColorScheme? {
        switch theme {
        case "light":
            return .light
        case "dark":
            return .dark
        default: // "auto"
            return nil // Uses system default
        }
    }

    var body: some Scene {
        MenuBarExtra("📋 SimpleCP", systemImage: "doc.on.clipboard") {
            ContentView()
                .environmentObject(clipboardManager)
                .environmentObject(backendService)
                .fontPreferences(fontPreferences)
                .preferredColorScheme(colorScheme)
                .frame(width: windowDimensions.width, height: windowDimensions.height)
                .id(windowSize) // Force view recreation when size changes
                .animation(.easeInOut(duration: 0.2), value: windowSize)
                .task {
                    // Set up shared reference for cleanup
                    AppDelegate.sharedBackendService = backendService
                    // Backend is auto-started in BackendService.init() with exponential backoff
                }
                .onChange(of: windowSize) { newSize in
                    print("🔵 Window size setting changed to: \(newSize)")
                    print("🔵 New dimensions: \(windowDimensions)")
                }
                .onChange(of: theme) { newTheme in
                    print("🎨 Theme changed to: \(newTheme)")
                }
        }
        .menuBarExtraStyle(.window)

        // Settings window
        Window("Settings", id: "settings") {
            SettingsWindow()
                .environmentObject(clipboardManager)
                .environmentObject(backendService)
                .fontPreferences(fontPreferences)
                .preferredColorScheme(colorScheme)
                .frame(width: 500, height: 400)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }

}

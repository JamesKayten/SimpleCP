//
//  SimpleCPApp.swift
//  SimpleCP
//
//  Created by SimpleCP
//

import SwiftUI
import AppKit
import ApplicationServices

@available(macOS 14.0, *)
@main
struct SimpleCPApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var clipboardManager = ClipboardManager()
    @StateObject private var backendService = BackendService()
    @AppStorage("windowWidth") private var windowWidth = 400
    @AppStorage("windowHeight") private var windowHeight = 450
    @AppStorage("theme") private var theme = "auto"
    @Environment(\.openSettings) private var openSettings
    
    // Font preferences
    @AppStorage("interfaceFont") private var interfaceFont: String = "SF Pro"
    @AppStorage("interfaceFontSize") private var interfaceFontSize: Double = 13.0
    @AppStorage("clipFont") private var clipFont: String = "SF Mono"
    @AppStorage("clipFontSize") private var clipFontSize: Double = 12.0

    init() {
        // Check accessibility permissions silently (no prompt)
        checkAccessibilityPermissionsSilent()
        
        // Show welcome screen on first launch
        Task { @MainActor in
            FirstLaunchManager.shared.showWelcomeIfNeeded()
        }
    }
    
    private func checkAccessibilityPermissionsSilent() {
        // Check without showing prompt - user can enable manually if needed
        let trusted = AXIsProcessTrusted()

        // Update the shared permission monitor immediately on launch
        // This ensures UI reflects correct state after rebuild/restart
        AccessibilityPermissionMonitor.shared.checkPermission()

        #if DEBUG
        if !trusted {
            print("ℹ️  Accessibility permissions not granted (optional for 'Paste Immediately' feature)")
        } else {
            print("✅ Accessibility permissions granted")
        }
        #endif
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
        // Hidden main window (required for SwiftUI App lifecycle)
        WindowGroup {
            MenuBarSetupView(
                clipboardManager: clipboardManager,
                backendService: backendService,
                fontPreferences: fontPreferences,
                colorScheme: colorScheme,
                windowWidth: $windowWidth,
                windowHeight: $windowHeight,
                theme: $theme
            )
            .frame(width: 0, height: 0)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 0, height: 0)
        
        // Settings scene - native macOS settings window
        Settings {
            SettingsWindow()
                .environmentObject(clipboardManager)
                .environmentObject(backendService)
                .fontPreferences(fontPreferences)
                .preferredColorScheme(colorScheme)
        }
    }
    
}

// MARK: - Menu Bar Setup View

@available(macOS 14.0, *)
private struct MenuBarSetupView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    @ObservedObject var backendService: BackendService
    let fontPreferences: FontPreferences
    let colorScheme: ColorScheme?
    @Binding var windowWidth: Int
    @Binding var windowHeight: Int
    @Binding var theme: String
    @Environment(\.openSettings) private var openSettings
    
    var body: some View {
        Color.clear
            .onAppear {
                setupApp()
            }
            .onChange(of: theme) { newValue in
                // Update the window appearance
                updateWindowAppearance()
            }
    }
    
    private func updateWindowAppearance() {
        getMenuBarManager().updatePopoverAppearance()
    }
    
    private func setupApp() {
        // Register shared instances
        clipboardManager.makeShared()
        backendService.makeShared()
        
        // Set up shared reference for cleanup
        AppDelegate.sharedBackendService = backendService
        
        // Kill any process on our port before starting
        let backendPort = UserDefaults.standard.integer(forKey: "backendPort")
        let port = backendPort == 0 ? 49917 : backendPort
        
        #if DEBUG
        print("🚀 SimpleCP starting...")
        print("   Backend port: \(port)")
        #endif
        
        if backendService.isPortInUse(port) {
            _ = backendService.killProcessOnPort(port)
        }
        
        // Register the openSettings action for WindowManager
        WindowManager.openSettingsAction = {
            openSettings()
        }
        
        // Set up the menu bar with content
        let contentView = ContentView()
            .environmentObject(clipboardManager)
            .environmentObject(backendService)
            .fontPreferences(fontPreferences)
            .preferredColorScheme(colorScheme)
        
        // Set up the menu bar manager with content
        setupMenuBar(with: contentView)
        
        // Hide the hidden SwiftUI window
        DispatchQueue.main.async {
            NSApp.windows.forEach { window in
                if window.title.isEmpty || window.title == "SimpleCP" {
                    window.close()
                }
            }
        }
    }
    
    private func setupMenuBar(with contentView: some View) {
        // Set up the menu bar manager with the content view
        getMenuBarManager().setContentView(contentView)
    }
    
    // Helper function to get the correct MenuBarManager instance
    // This provides explicit type context to resolve ambiguity
    private func getMenuBarManager() -> MenuBarManager {
        return MenuBarManager.shared
    }
}



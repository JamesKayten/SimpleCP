//
//  SimpleCPApp.swift
//  SimpleCP
//
//  Created by SimpleCP
//

import SwiftUI
import AppKit
import ApplicationServices

@main
struct SimpleCPApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var clipboardManager = ClipboardManager()
    @StateObject private var backendService = BackendService()
    @AppStorage("windowSize") private var windowSize = "compact"  // Default to compact for simplicity
    @AppStorage("theme") private var theme = "auto"
    @Environment(\.openWindow) private var openWindow
    
    // Font preferences
    @AppStorage("interfaceFont") private var interfaceFont: String = "SF Pro"
    @AppStorage("interfaceFontSize") private var interfaceFontSize: Double = 13.0
    @AppStorage("clipFont") private var clipFont: String = "SF Mono"
    @AppStorage("clipFontSize") private var clipFontSize: Double = 12.0

    init() {
        // Register shared instances for WindowManager
        clipboardManager.makeShared()
        backendService.makeShared()
        
        // Check accessibility permissions silently (no prompt)
        checkAccessibilityPermissionsSilent()
        
        // Enhanced debug logging for backend issues
        print("\n" + String(repeating: "=", count: 60))
        print("🚀 SIMPLECP STARTUP DIAGNOSTICS")
        print(String(repeating: "=", count: 60))
        
        let backendPort = UserDefaults.standard.integer(forKey: "backendPort")
        let port = backendPort == 0 ? 8000 : backendPort
        print("🔍 Backend Port: \(port)")
        print("🔍 Current Directory: \(FileManager.default.currentDirectoryPath)")
        print("🔍 Bundle Path: \(Bundle.main.bundlePath)")
        
        // ALWAYS kill anything on port 8000 - no mercy
        print("\n🔴 FORCE KILLING PORT \(port)")
        let killed = forceKillPort(port)
        if killed {
            print("✅ Port \(port) freed successfully")
        } else {
            print("⚠️ Port \(port) was already free or couldn't be killed")
        }
        
        // Check venv permissions
        let projectPath = "/Volumes/User_Smallfavor/Users/Smallfavor/Code/ACTIVE/SimpleCP"
        let venvConfig = "\(projectPath)/.venv/pyvenv.cfg"
        let venvPython = "\(projectPath)/.venv/bin/python3"
        let backendMain = "\(projectPath)/backend/main.py"
        
        print("\n📁 FILE SYSTEM CHECKS:")
        print("   - venv python exists: \(FileManager.default.fileExists(atPath: venvPython) ? "✅" : "❌")")
        print("   - pyvenv.cfg exists: \(FileManager.default.fileExists(atPath: venvConfig) ? "✅" : "❌")")
        print("   - pyvenv.cfg readable: \(FileManager.default.isReadableFile(atPath: venvConfig) ? "✅" : "❌")")
        print("   - backend/main.py exists: \(FileManager.default.fileExists(atPath: backendMain) ? "✅" : "❌")")
        
        // Check sandbox status
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let isSandboxed = homeDir.contains("Containers")
        print("\n🔒 SANDBOX STATUS:")
        print("   - Home directory: \(homeDir)")
        print("   - App is sandboxed: \(isSandboxed ? "⚠️ YES" : "✅ No")")
        
        // Try to actually read the file
        checkFileAccessPermissions()
        
        print(String(repeating: "=", count: 60) + "\n")
    }
    
    private func forceKillPort(_ port: Int) -> Bool {
        print("🔪 Executing: lsof -ti:\(port) | xargs kill -9")
        
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "lsof -ti:\(port) | xargs kill -9 2>/dev/null; exit 0"]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            // Wait for port to fully release
            Thread.sleep(forTimeInterval: 0.5)
            
            // Verify port is free
            return !isPortInUse(port)
        } catch {
            print("⚠️ Failed to execute kill command: \(error.localizedDescription)")
            return false
        }
    }
    
    private func isPortInUse(_ port: Int) -> Bool {
        let task = Process()
        task.launchPath = "/usr/sbin/lsof"
        task.arguments = ["-t", "-i:\(port)"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return !output.isEmpty
        } catch {
            return false
        }
    }
    
    private func checkAccessibilityPermissionsSilent() {
        // Check without showing prompt - user can enable manually if needed
        let trusted = AXIsProcessTrusted()
        
        if !trusted {
            print("ℹ️  Accessibility permissions not granted (optional for 'Paste Immediately' feature)")
            print("   To enable: System Settings > Privacy & Security > Accessibility")
        } else {
            print("✅ Accessibility permissions granted")
        }
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
    
    private func checkFileAccessPermissions() {
        let projectPath = "/Volumes/User_Smallfavor/Users/Smallfavor/Code/ACTIVE/SimpleCP"
        let venvConfig = "\(projectPath)/.venv/pyvenv.cfg"
        
        // Try to read the file
        if let contents = try? String(contentsOfFile: venvConfig, encoding: .utf8) {
            print("✅ Successfully read pyvenv.cfg (first 200 chars):")
            print(String(contents.prefix(200)))
        } else {
            print("❌ Cannot read pyvenv.cfg - file access permission denied")
            print("   You may need to grant Full Disk Access or disable App Sandbox")
        }
    }
    
    // MARK: - Terminal Commands for Manual Cleanup
    
    /// Run this in Terminal to kill zombie backend processes:
    /// lsof -ti:8000 | xargs kill -9
    ///
    /// Or to check what's using the port:
    /// lsof -i:8000
    
    // MARK: - Window Size Calculation
    
    private var windowDimensions: (width: CGFloat, height: CGFloat) {
        switch windowSize {
        case "compact":
            return (400, 450)
        case "normal":
            return (450, 500)
        case "large":
            return (550, 650)
        default:
            return (450, 500) // fallback to normal
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
        // Hidden main window (required for SwiftUI App lifecycle)
        WindowGroup {
            MenuBarSetupView(
                clipboardManager: clipboardManager,
                backendService: backendService,
                fontPreferences: fontPreferences,
                colorScheme: colorScheme,
                windowDimensions: windowDimensions,
                windowSize: $windowSize,
                theme: $theme
            )
            .frame(width: 0, height: 0)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 0, height: 0)
        
        // Settings window - only opens when explicitly requested  
        Window("Settings", id: "settings") {
            SettingsWindow()
                .environmentObject(clipboardManager)
                .environmentObject(backendService)
                .fontPreferences(fontPreferences)
                .preferredColorScheme(colorScheme)
                .onAppear {
                    // Make the window behave like an auxiliary window
                    if let window = NSApp.windows.first(where: { $0.title == "Settings" }) {
                        window.level = .floating
                        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
                        
                        // Add escape key handler
                        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                            if event.keyCode == 53 { // Escape key
                                window.close()
                                return nil
                            }
                            return event
                        }
                    }
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 500, height: 400)
    }
    
}

// MARK: - Menu Bar Setup View

private struct MenuBarSetupView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    @ObservedObject var backendService: BackendService
    let fontPreferences: FontPreferences
    let colorScheme: ColorScheme?
    let windowDimensions: (width: CGFloat, height: CGFloat)
    @Binding var windowSize: String
    @Binding var theme: String
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        Color.clear
            .onAppear {
                // Register the openWindow action for WindowManager
                WindowManager.openWindowAction = { id in
                    openWindow(id: id)
                }
                
                self.setupMenuBarContent()
                self.hideInitialWindows()
            }
            .onChange(of: windowSize) { newSize in
                print("🔵 Window size setting changed to: \(newSize)")
                print("🔵 New dimensions: \(windowDimensions)")
                self.setupMenuBarContent()
                MenuBarManager.shared.updateWindowSize()
            }
            .onChange(of: theme) { newTheme in
                print("🎨 Theme changed to: \(newTheme)")
                self.setupMenuBarContent()
            }
    }
    
    private func setupMenuBarContent() {
        let contentView = ContentView()
            .environmentObject(clipboardManager)
            .environmentObject(backendService)
            .fontPreferences(fontPreferences)
            .preferredColorScheme(colorScheme)
            .task {
                // Set up shared reference for cleanup
                AppDelegate.sharedBackendService = backendService
                // Backend is auto-started in BackendService.init() with exponential backoff
            }
        
        MenuBarManager.shared.setContentView(contentView)
    }
    
    private func hideInitialWindows() {
        DispatchQueue.main.async {
            NSApp.windows.forEach { window in
                if window.title.isEmpty || window.title == "SimpleCP" {
                    window.close()
                }
            }
        }
    }
}



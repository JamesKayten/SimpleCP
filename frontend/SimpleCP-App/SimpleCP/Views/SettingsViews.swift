//  SettingsViews.swift - Settings tab view components
import SwiftUI

// MARK: - General Settings View
struct GeneralSettingsView: View {
    @Binding var launchAtLogin: Bool
    @Binding var theme: String
    @Binding var apiHost: String
    @Binding var apiPort: Int
    @AppStorage("showInDock") private var showInDock = true
    
    @State private var hasAppeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GENERAL SETTINGS")
                .font(.subheadline)
                .fontWeight(.semibold)

            // Startup
            GroupBox(label: Text("Startup")) {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Launch at login", isOn: $launchAtLogin)
                }
                .padding(.vertical, 4)
            }
            
            // Theme
            GroupBox(label: Text("Theme")) {
                HStack {
                    Picker("", selection: $theme) {
                        Text("Auto").tag("auto")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.radioGroup)
                    .onChange(of: theme) { newValue in
                        guard hasAppeared else { return }
                        // Apply theme change immediately to main window and settings window
                        applyThemeToAllWindows(newValue)
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
            }
            
            // Menu Bar Behavior
            GroupBox(label: Text("Menu Bar")) {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Show app icon in Dock", isOn: $showInDock)
                        .onChange(of: showInDock) { newValue in
                            guard hasAppeared else { return }
                            // Update activation policy immediately
                            NSApp.setActivationPolicy(newValue ? .regular : .accessory)
                        }
                    
                    Text("Showing in Dock fixes keyboard input issues in dialogs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }

            // API Configuration
            GroupBox(label: Text("Backend API")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Host:")
                        TextField("localhost", text: $apiHost)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 150)
                            .disabled(true) // Localhost only for now
                    }

                    HStack {
                        Text("Port:")
                        TextField("49917", value: $apiPort, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }

                    Text("Default port is 49917. Restart the app after changing.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            hasAppeared = true
        }
        .onDisappear {
            hasAppeared = false
        }
    }
    
    // MARK: - Helper Functions
    
    private func applyThemeToAllWindows(_ theme: String) {
        // Update the main popover window
        DispatchQueue.main.async {
            MenuBarManager.shared.updatePopoverAppearance()
            
            // Update the settings window
            if let settingsWindow = NSApp.windows.first(where: { $0.title == "Settings" }) {
                switch theme {
                case "light":
                    settingsWindow.appearance = NSAppearance(named: .aqua)
                case "dark":
                    settingsWindow.appearance = NSAppearance(named: .darkAqua)
                default: // "auto"
                    settingsWindow.appearance = nil // Use system default
                }
            }
        }
    }
}

// MARK: - Appearance Settings View

struct AppearanceSettingsView: View {
    @Binding var windowWidth: Int
    @Binding var windowHeight: Int
    @Binding var windowOpacity: Double
    @Binding var interfaceFont: String
    @Binding var interfaceFontSize: Double
    @Binding var clipFont: String
    @Binding var clipFontSize: Double
    
    // Debouncing state for opacity changes
    @State private var opacityDebounceTask: Task<Void, Never>?
    @State private var lastAppliedOpacity: Double = 0.0
    @State private var hasAppeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Window Size
            GroupBox(label: Text("Window Size")) {
                VStack(alignment: .leading, spacing: 12) {
                    // Width Slider
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Width:")
                                    .frame(width: 50, alignment: .leading)
                                
                                Slider(value: Binding(
                                    get: { Double(windowWidth) },
                                    set: { windowWidth = Int($0) }
                                ), in: 250...800, step: 10)
                                .onChange(of: windowWidth) { newValue in
                                    guard hasAppeared else { return }
                                    MenuBarManager.shared.updateWindowSize(width: newValue, height: windowHeight)
                                }
                                
                                Text("\(windowWidth)px")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 60, alignment: .trailing)
                            }
                        }
                        
                        // Height Slider
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Height:")
                                    .frame(width: 50, alignment: .leading)
                                
                                Slider(value: Binding(
                                    get: { Double(windowHeight) },
                                    set: { windowHeight = Int($0) }
                                ), in: 300...800, step: 10)
                                .onChange(of: windowHeight) { newValue in
                                    guard hasAppeared else { return }
                                    MenuBarManager.shared.updateWindowSize(width: windowWidth, height: newValue)
                                }
                                
                                Text("\(windowHeight)px")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 60, alignment: .trailing)
                            }
                        }
                }
                .padding(.vertical, 8)
            }

            // Window Opacity
            GroupBox(label: Text("Window Opacity")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("90%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 35, alignment: .leading)
                        
                        Slider(value: $windowOpacity, in: 0.90...1.0, step: 0.01) {
                            Text("Opacity")
                        }
                        .onChange(of: windowOpacity) { newValue in
                            guard hasAppeared else { return }
                            // Debounce opacity changes to avoid excessive updates while sliding
                            opacityDebounceTask?.cancel()
                            opacityDebounceTask = Task { @MainActor in
                                // Wait a brief moment to see if more changes are coming
                                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                                guard !Task.isCancelled else { return }
                                applyOpacityToMainWindow(newValue)
                            }
                        }
                        
                        Text("100%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 35, alignment: .trailing)
                    }
                    
                    Text("\(Int(windowOpacity * 100))% - Changes apply immediately")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }

            // Fonts
            GroupBox(label: Text("Fonts")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Interface:")
                        Picker("", selection: $interfaceFont) {
                            Text("SF Pro").tag("SF Pro")
                            Text("SF Mono").tag("SF Mono")
                            Text("Helvetica").tag("Helvetica")
                        }
                        .frame(width: 150)

                        Text("Size:")
                        Picker("", selection: $interfaceFontSize) {
                            ForEach([11.0, 12.0, 13.0, 14.0, 15.0], id: \.self) { size in
                                Text("\(Int(size))").tag(size)
                            }
                        }
                        .frame(width: 70)
                    }

                    HStack {
                        Text("Clips:")
                        Picker("", selection: $clipFont) {
                            Text("SF Mono").tag("SF Mono")
                            Text("Menlo").tag("Menlo")
                            Text("Monaco").tag("Monaco")
                        }
                        .frame(width: 150)

                        Text("Size:")
                        Picker("", selection: $clipFontSize) {
                            ForEach([10.0, 11.0, 12.0, 13.0, 14.0], id: \.self) { size in
                                Text("\(Int(size))").tag(size)
                            }
                        }
                        .frame(width: 70)
                    }
                    
                    Text("Interface font affects labels and UI elements. Clip font affects clipboard content display.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            // Initialize the tracking variable to prevent initial spurious updates
            lastAppliedOpacity = windowOpacity
            // Mark that the view has appeared - now we can process changes
            hasAppeared = true
        }
        .onDisappear {
            // Cancel any pending tasks when view disappears
            opacityDebounceTask?.cancel()
            opacityDebounceTask = nil
            hasAppeared = false
        }
    }
    
    // MARK: - Helper Functions
    
    private func applyOpacityToMainWindow(_ opacity: Double) {
        // Prevent redundant updates - only apply if the value has actually changed
        guard abs(lastAppliedOpacity - opacity) > 0.001 else {
            return
        }
        
        // Only apply if the window actually exists and is visible
        guard MenuBarManager.shared.isWindowVisible() else { 
            return 
        }
        
        // Update tracking variable
        lastAppliedOpacity = opacity
        
        // Update the main popover window
        MenuBarManager.shared.updatePopoverOpacity(opacity)
    }
}

// MARK: - Data Settings View (Combined Clips + Snippets)

struct DataSettingsView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @Binding var maxHistorySize: Int
    @Binding var showSnippetPreviews: Bool
    @Binding var clipPreviewDelay: Double
    @Binding var folderFlyoutDelay: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CLIPS & SNIPPETS")
                .font(.subheadline)
                .fontWeight(.semibold)

            // Display Options
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Preview on Hover", isOn: $showSnippetPreviews)
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        // Clip Preview Delay
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Clip preview:")
                                    .frame(width: 110, alignment: .leading)
                                
                                Slider(value: $clipPreviewDelay, in: 0.3...2.0, step: 0.1) {
                                    Text("Delay")
                                }
                                
                                Text("\(String(format: "%.1f", clipPreviewDelay))s")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 40, alignment: .trailing)
                            }
                        }
                        
                        // Folder Contents Delay
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Folder contents:")
                                    .frame(width: 110, alignment: .leading)
                                
                                Slider(value: $folderFlyoutDelay, in: 0.3...2.0, step: 0.1) {
                                    Text("Delay")
                                }
                                
                                Text("\(String(format: "%.1f", folderFlyoutDelay))s")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 40, alignment: .trailing)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            // Snippets Statistics
            GroupBox(label: Text("Snippets")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Total snippets:")
                        Spacer()
                        Text("\(clipboardManager.snippets.count)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Total folders:")
                        Spacer()
                        Text("\(clipboardManager.folders.count)")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            // Clips History
            GroupBox(label: Text("Clipboard History")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Maximum history size:")
                        Picker("", selection: $maxHistorySize) {
                            Text("25").tag(25)
                            Text("50").tag(50)
                            Text("100").tag(100)
                            Text("200").tag(200)
                        }
                        .frame(width: 100)
                    }

                    Text("Number of clipboard items to keep in history")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Clips Settings View (Legacy - kept for compatibility)

struct ClipsSettingsView: View {
    @Binding var maxHistorySize: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("CLIPS SETTINGS")
                .font(.headline)

            GroupBox(label: Text("History")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Maximum history size:")
                        Picker("", selection: $maxHistorySize) {
                            Text("25").tag(25)
                            Text("50").tag(50)
                            Text("100").tag(100)
                            Text("200").tag(200)
                        }
                        .frame(width: 100)
                    }

                    Text("Number of clipboard items to keep in history")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Snippets Settings View (Legacy - kept for compatibility)

struct SnippetsSettingsView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("SNIPPETS SETTINGS")
                .font(.headline)

            GroupBox(label: Text("Statistics")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Total snippets:")
                        Spacer()
                        Text("\(clipboardManager.snippets.count)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Total folders:")
                        Spacer()
                        Text("\(clipboardManager.folders.count)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Favorite snippets:")
                        Spacer()
                        Text("\(clipboardManager.snippets.filter { $0.isFavorite }.count)")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

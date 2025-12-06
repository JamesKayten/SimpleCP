//  SettingsViews.swift - Settings tab view components
import SwiftUI

// MARK: - General Settings View
struct GeneralSettingsView: View {
    @Binding var launchAtLogin: Bool
    @Binding var startMinimized: Bool
    @Binding var windowPosition: String
    @Binding var windowSize: String
    @Binding var apiHost: String
    @Binding var apiPort: Int
    @AppStorage("showInDock") private var showInDock = true

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("GENERAL SETTINGS")
                .font(.headline)

            // Startup
            GroupBox(label: Text("Startup")) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Launch at login", isOn: $launchAtLogin)
                    Toggle("Start minimized", isOn: $startMinimized)
                }
                .padding(.vertical, 8)
            }
            
            // Menu Bar Behavior
            GroupBox(label: Text("Menu Bar")) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Show app icon in Dock", isOn: $showInDock)
                        .onChange(of: showInDock) { newValue in
                            // Update activation policy immediately
                            NSApp.setActivationPolicy(newValue ? .regular : .accessory)
                        }
                    
                    Text("Showing in Dock fixes keyboard input issues in dialogs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }

            // Window
            GroupBox(label: Text("Window")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Position:")
                        Picker("", selection: $windowPosition) {
                            Text("Center").tag("center")
                            Text("Remember last position").tag("remember")
                        }
                        .pickerStyle(.radioGroup)
                    }

                    HStack {
                        Text("Size:")
                        Picker("", selection: $windowSize) {
                            Text("Compact").tag("compact")
                            Text("Normal").tag("normal")
                            Text("Large").tag("large")
                        }
                        .pickerStyle(.radioGroup)
                    }
                    
                    Text("Size changes apply when you reopen the SimpleCP window")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }

            // API Configuration
            GroupBox(label: Text("Backend API")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Host:")
                        TextField("localhost", text: $apiHost)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 150)
                            .disabled(true) // Localhost only for now
                    }

                    HStack {
                        Text("Port:")
                        TextField("49917", value: $apiPort, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        
                        Text("(Changes require restart)")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }

                    Text("⚠️ Backend must be manually reconfigured to use a different port")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }

            // Shortcuts
            GroupBox(label: Text("Keyboard Shortcuts")) {
                VStack(alignment: .leading, spacing: 12) {
                    ShortcutRow(label: "Open SimpleCP:", shortcut: "⌘⌥V")
                    ShortcutRow(label: "Quick search:", shortcut: "⌘⌥F")
                    ShortcutRow(label: "Paste #1:", shortcut: "⌘⌥1")
                }
                .padding(.vertical, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Shortcut Row Helper

struct ShortcutRow: View {
    let label: String
    let shortcut: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .padding(4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
            Button("Set") {
                // TODO: Implement shortcut customization
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - Appearance Settings View

struct AppearanceSettingsView: View {
    @Binding var theme: String
    @Binding var windowOpacity: Double
    @Binding var interfaceFont: String
    @Binding var interfaceFontSize: Double
    @Binding var clipFont: String
    @Binding var clipFontSize: Double
    @Binding var showFolderIcons: Bool
    @Binding var animateFolderExpand: Bool
    @Binding var showSnippetPreviews: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("APPEARANCE SETTINGS")
                .font(.headline)

            // Theme
            GroupBox(label: Text("Theme")) {
                HStack {
                    Picker("", selection: $theme) {
                        Text("Auto").tag("auto")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.radioGroup)

                    Spacer()
                }
                .padding(.vertical, 8)
            }

            // Window Opacity
            GroupBox(label: Text("Window Opacity")) {
                VStack(alignment: .leading, spacing: 8) {
                    Slider(value: $windowOpacity, in: 0.5...1.0, step: 0.05) {
                        Text("Opacity")
                    }
                    Text("\(Int(windowOpacity * 100))%")
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

            // Display Options
            GroupBox(label: Text("Display Options")) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Show folder icons", isOn: $showFolderIcons)
                    Toggle("Animate folder expand/collapse", isOn: $animateFolderExpand)
                    Toggle("Show snippet previews on hover", isOn: $showSnippetPreviews)
                    
                    Text("Previews appear after hovering for 1.5 seconds")
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

// MARK: - Clips Settings View

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

            GroupBox(label: Text("Content Detection")) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Auto-detect URLs", isOn: .constant(true))
                    Toggle("Auto-detect email addresses", isOn: .constant(true))
                    Toggle("Auto-detect code snippets", isOn: .constant(true))

                    Text("Automatically categorize clipboard content by type")
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

// MARK: - Snippets Settings View

struct SnippetsSettingsView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("SNIPPETS SETTINGS")
                .font(.headline)

            GroupBox(label: Text("Snippet Behavior")) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable smart name suggestions", isOn: .constant(true))
                    Toggle("Auto-suggest tags", isOn: .constant(true))
                    Toggle("Confirm before deleting snippets", isOn: .constant(true))

                    Text("Configure how snippets are created and managed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }

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

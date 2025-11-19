//
//  SettingsWindow.swift
//  SimpleCP
//
//  Created by SimpleCP
//

import SwiftUI

struct SettingsWindow: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("startMinimized") private var startMinimized = false
    @AppStorage("windowPosition") private var windowPosition = "center"
    @AppStorage("windowSize") private var windowSize = "normal"
    @AppStorage("maxHistorySize") private var maxHistorySize = 50
    @AppStorage("theme") private var theme = "auto"
    @AppStorage("windowOpacity") private var windowOpacity = 0.9
    @AppStorage("interfaceFont") private var interfaceFont = "SF Pro"
    @AppStorage("interfaceFontSize") private var interfaceFontSize = 13.0
    @AppStorage("clipFont") private var clipFont = "SF Mono"
    @AppStorage("clipFontSize") private var clipFontSize = 12.0
    @AppStorage("showFolderIcons") private var showFolderIcons = true
    @AppStorage("animateFolderExpand") private var animateFolderExpand = true
    @AppStorage("showSnippetPreviews") private var showSnippetPreviews = false

    enum Tab {
        case general, appearance, clips, snippets
    }

    @State private var selectedTab: Tab = .general

    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            HStack(spacing: 20) {
                TabButton(
                    title: "General",
                    icon: "gearshape",
                    isSelected: selectedTab == .general
                ) {
                    selectedTab = .general
                }

                TabButton(
                    title: "Appearance",
                    icon: "paintbrush",
                    isSelected: selectedTab == .appearance
                ) {
                    selectedTab = .appearance
                }

                TabButton(
                    title: "Clips",
                    icon: "doc.on.clipboard",
                    isSelected: selectedTab == .clips
                ) {
                    selectedTab = .clips
                }

                TabButton(
                    title: "Snippets",
                    icon: "folder",
                    isSelected: selectedTab == .snippets
                ) {
                    selectedTab = .snippets
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Content Area
            ScrollView {
                Group {
                    switch selectedTab {
                    case .general:
                        GeneralSettingsView(
                            launchAtLogin: $launchAtLogin,
                            startMinimized: $startMinimized,
                            windowPosition: $windowPosition,
                            windowSize: $windowSize
                        )
                    case .appearance:
                        AppearanceSettingsView(
                            theme: $theme,
                            windowOpacity: $windowOpacity,
                            interfaceFont: $interfaceFont,
                            interfaceFontSize: $interfaceFontSize,
                            clipFont: $clipFont,
                            clipFontSize: $clipFontSize,
                            showFolderIcons: $showFolderIcons,
                            animateFolderExpand: $animateFolderExpand,
                            showSnippetPreviews: $showSnippetPreviews
                        )
                    case .clips:
                        ClipsSettingsView(
                            maxHistorySize: $maxHistorySize
                        )
                    case .snippets:
                        SnippetsSettingsView()
                    }
                }
                .padding()
            }

            Divider()

            // Footer
            HStack {
                Button("Reset to Defaults") {
                    resetToDefaults()
                }
                .buttonStyle(.bordered)

                Spacer()

                Text("SimpleCP v1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }

    private func resetToDefaults() {
        launchAtLogin = false
        startMinimized = false
        windowPosition = "center"
        windowSize = "normal"
        maxHistorySize = 50
        theme = "auto"
        windowOpacity = 0.9
        interfaceFontSize = 13.0
        clipFontSize = 12.0
        showFolderIcons = true
        animateFolderExpand = true
        showSnippetPreviews = false
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(.system(size: 11))
            }
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .frame(minWidth: 80)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - General Settings View

struct GeneralSettingsView: View {
    @Binding var launchAtLogin: Bool
    @Binding var startMinimized: Bool
    @Binding var windowPosition: String
    @Binding var windowSize: String

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
                }
                .padding(.vertical, 8)
            }

            // Shortcuts
            GroupBox(label: Text("Keyboard Shortcuts")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Open SimpleCP:")
                        Spacer()
                        Text("⌘⌥V")
                            .font(.system(.body, design: .monospaced))
                            .padding(4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                        Button("Set") {
                            // TODO: Implement shortcut customization
                        }
                        .buttonStyle(.bordered)
                    }

                    HStack {
                        Text("Quick search:")
                        Spacer()
                        Text("⌘⌥F")
                            .font(.system(.body, design: .monospaced))
                            .padding(4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                        Button("Set") {
                            // TODO: Implement shortcut customization
                        }
                        .buttonStyle(.bordered)
                    }

                    HStack {
                        Text("Paste #1:")
                        Spacer()
                        Text("⌘⌥1")
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
                .padding(.vertical, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                }
                .padding(.vertical, 8)
            }

            // Display Options
            GroupBox(label: Text("Display Options")) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Show folder icons", isOn: $showFolderIcons)
                    Toggle("Animate folder expand/collapse", isOn: $animateFolderExpand)
                    Toggle("Show snippet previews on hover", isOn: $showSnippetPreviews)
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

// MARK: - Preview

#Preview {
    SettingsWindow()
        .environmentObject(ClipboardManager())
        .frame(width: 500, height: 400)
}

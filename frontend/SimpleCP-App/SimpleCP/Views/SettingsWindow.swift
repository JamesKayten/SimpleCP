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
    @AppStorage("windowSize") private var windowSize = "compact"
    @AppStorage("maxHistorySize") private var maxHistorySize = 50
    @AppStorage("theme") private var theme = "auto"
    @AppStorage("windowOpacity") private var windowOpacity = 0.95
    @AppStorage("interfaceFont") private var interfaceFont = "SF Pro"
    @AppStorage("interfaceFontSize") private var interfaceFontSize = 13.0
    @AppStorage("clipFont") private var clipFont = "SF Mono"
    @AppStorage("clipFontSize") private var clipFontSize = 12.0
    @AppStorage("showSnippetPreviews") private var showSnippetPreviews = false
    @AppStorage("apiHost") private var apiHost = "localhost"
    @AppStorage("apiPort") private var apiPort = 49917

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
                            windowSize: $windowSize,
                            apiHost: $apiHost,
                            apiPort: $apiPort
                        )
                    case .appearance:
                        AppearanceSettingsView(
                            theme: $theme,
                            windowOpacity: $windowOpacity,
                            interfaceFont: $interfaceFont,
                            interfaceFontSize: $interfaceFontSize,
                            clipFont: $clipFont,
                            clipFontSize: $clipFontSize,
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
        windowSize = "compact"
        maxHistorySize = 50
        theme = "auto"
        windowOpacity = 0.95
        interfaceFontSize = 13.0
        clipFontSize = 12.0
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

// MARK: - Preview

#Preview {
    SettingsWindow()
        .environmentObject(ClipboardManager())
        .frame(width: 500, height: 400)
}

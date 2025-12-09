//
//  SettingsWindow.swift
//  SimpleCP
//
//  Created by SimpleCP
//

import SwiftUI

@available(macOS 14.0, *)
struct SettingsWindow: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("startMinimized") private var startMinimized = false
    @AppStorage("windowPosition") private var windowPosition = "center"
    @AppStorage("windowSize") private var windowSize = "medium"
    @AppStorage("windowWidth") private var windowWidth = 400
    @AppStorage("windowHeight") private var windowHeight = 450
    @AppStorage("maxHistorySize") private var maxHistorySize = 50
    @AppStorage("theme") private var theme = "auto"
    @AppStorage("windowOpacity") private var windowOpacity = 0.95
    @AppStorage("interfaceFont") private var interfaceFont = "SF Pro"
    @AppStorage("interfaceFontSize") private var interfaceFontSize = 13.0
    @AppStorage("clipFont") private var clipFont = "SF Mono"
    @AppStorage("clipFontSize") private var clipFontSize = 12.0
    @AppStorage("showSnippetPreviews") private var showSnippetPreviews = false
    @AppStorage("clipPreviewDelay") private var clipPreviewDelay = 0.7
    @AppStorage("clipGroupFlyoutDelay") private var clipGroupFlyoutDelay = 0.5
    @AppStorage("folderFlyoutDelay") private var folderFlyoutDelay = 1.0
    @AppStorage("apiHost") private var apiHost = "localhost"
    @AppStorage("apiPort") private var apiPort = 49917

    enum Tab {
        case general, appearance, clips
    }

    @State private var selectedTab: Tab = .general

    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            HStack(spacing: 15) {
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
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Content Area
            ScrollView {
                Group {
                    switch selectedTab {
                    case .general:
                        GeneralSettingsView(
                            launchAtLogin: $launchAtLogin,
                            theme: $theme,
                            apiHost: $apiHost,
                            apiPort: $apiPort
                        )
                    case .appearance:
                        AppearanceSettingsView(
                            windowWidth: $windowWidth,
                            windowHeight: $windowHeight,
                            windowOpacity: $windowOpacity,
                            interfaceFont: $interfaceFont,
                            interfaceFontSize: $interfaceFontSize,
                            clipFont: $clipFont,
                            clipFontSize: $clipFontSize
                        )
                    case .clips:
                        DataSettingsView(
                            maxHistorySize: $maxHistorySize,
                            showSnippetPreviews: $showSnippetPreviews,
                            clipPreviewDelay: $clipPreviewDelay,
                            folderFlyoutDelay: $folderFlyoutDelay
                        )
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .id(selectedTab) // Reset scroll position when tab changes
            .defaultScrollAnchor(.top)

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
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .frame(width: 360, height: 480)
        .onAppear {
            // Configure compact window with 1:2 aspect ratio like other preference windows
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Find the settings window - try multiple methods
                var settingsWindow: NSWindow?
                
                // Method 1: Look for "Settings" title
                settingsWindow = NSApp.windows.first(where: { $0.title == "Settings" })
                
                // Method 2: Look for any window that's not the main menubar window
                if settingsWindow == nil {
                    settingsWindow = NSApp.windows.first(where: { 
                        $0 != MenuBarManager.shared.menuBarWindow && 
                        $0.isVisible &&
                        $0.contentViewController != nil
                    })
                }
                
                // Method 3: Look for the most recently ordered window
                if settingsWindow == nil {
                    settingsWindow = NSApp.orderedWindows.first(where: { 
                        $0 != MenuBarManager.shared.menuBarWindow 
                    })
                }
                
                guard let window = settingsWindow else {
                    #if DEBUG
                    print("⚠️ Could not find settings window to configure")
                    print("Available windows: \(NSApp.windows.map { "\($0.title) - \(type(of: $0))" })")
                    #endif
                    return
                }
                
                #if DEBUG
                print("🔧 Configuring settings window: \(window.title)")
                #endif
                
                // Set initial size - tall and narrow (1:2 ratio)
                window.setContentSize(NSSize(width: 360, height: 480))
                
                // Set minimum size
                window.minSize = NSSize(width: 360, height: 480)
                
                // Set maximum size
                window.maxSize = NSSize(width: 450, height: 600)
                
                // Make it resizable
                window.styleMask.insert(.resizable)
                
                // Set window level to appear above the floating menu bar window
                window.level = .modalPanel
                
                // Ensure it's visible
                window.isReleasedWhenClosed = false
                
                // Center the window
                window.center()
                
                // Bring to front
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    private func resetToDefaults() {
        launchAtLogin = false
        startMinimized = false
        windowPosition = "center"
        windowSize = "medium"
        windowWidth = 400
        windowHeight = 450
        maxHistorySize = 50
        theme = "auto"
        windowOpacity = 0.95
        interfaceFontSize = 13.0
        clipFontSize = 12.0
        showSnippetPreviews = false
        clipPreviewDelay = 0.7
        clipGroupFlyoutDelay = 0.5
        folderFlyoutDelay = 1.0
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
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 10))
            }
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .frame(minWidth: 70)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    if #available(macOS 14.0, *) {
        SettingsWindow()
            .environmentObject(ClipboardManager())
            .frame(width: 500, height: 400)
    } else {
        // Fallback on earlier versions
    }
}



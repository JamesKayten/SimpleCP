//  SettingsViews.swift - Settings tab view components
//  Extensions: +Appearance

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
            Text("GENERAL SETTINGS").font(.subheadline).fontWeight(.semibold)

            GroupBox(label: Text("Startup")) {
                Toggle("Launch at login", isOn: $launchAtLogin).padding(.vertical, 4)
            }

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
                        applyThemeToAllWindows(newValue)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }

            GroupBox(label: Text("Menu Bar")) {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Show app icon in Dock", isOn: $showInDock)
                        .onChange(of: showInDock) { newValue in
                            guard hasAppeared else { return }
                            NSApp.setActivationPolicy(newValue ? .regular : .accessory)
                        }
                    Text("Showing in Dock fixes keyboard input issues in dialogs").font(.caption).foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }

            GroupBox(label: Text("Backend API")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Host:")
                        TextField("localhost", text: $apiHost).textFieldStyle(.roundedBorder).frame(width: 150).disabled(true)
                    }
                    HStack {
                        Text("Port:")
                        TextField("49917", value: $apiPort, formatter: NumberFormatter()).textFieldStyle(.roundedBorder).frame(width: 100)
                    }
                    Text("Default port is 49917. Restart the app after changing.").font(.caption).foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { hasAppeared = true }
        .onDisappear { hasAppeared = false }
    }

    private func applyThemeToAllWindows(_ theme: String) {
        DispatchQueue.main.async {
            MenuBarManager.shared.updatePopoverAppearance()
            if let settingsWindow = NSApp.windows.first(where: { $0.title == "Settings" }) {
                switch theme {
                case "light": settingsWindow.appearance = NSAppearance(named: .aqua)
                case "dark": settingsWindow.appearance = NSAppearance(named: .darkAqua)
                default: settingsWindow.appearance = nil
                }
            }
        }
    }
}

// MARK: - Data Settings View

struct DataSettingsView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @Binding var maxHistorySize: Int
    @Binding var showSnippetPreviews: Bool
    @Binding var clipPreviewDelay: Double
    @Binding var folderFlyoutDelay: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CLIPS & SNIPPETS").font(.subheadline).fontWeight(.semibold)

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Preview on Hover", isOn: $showSnippetPreviews)
                    Divider().padding(.vertical, 4)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Clip preview:").frame(width: 110, alignment: .leading)
                            Slider(value: $clipPreviewDelay, in: 0.3...2.0, step: 0.1)
                            Text("\(String(format: "%.1f", clipPreviewDelay))s").font(.caption).foregroundColor(.secondary).frame(width: 40, alignment: .trailing)
                        }
                        HStack {
                            Text("Folder contents:").frame(width: 110, alignment: .leading)
                            Slider(value: $folderFlyoutDelay, in: 0.3...2.0, step: 0.1)
                            Text("\(String(format: "%.1f", folderFlyoutDelay))s").font(.caption).foregroundColor(.secondary).frame(width: 40, alignment: .trailing)
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            GroupBox(label: Text("Snippets")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack { Text("Total snippets:"); Spacer(); Text("\(clipboardManager.snippets.count)").foregroundColor(.secondary) }
                    HStack { Text("Total folders:"); Spacer(); Text("\(clipboardManager.folders.count)").foregroundColor(.secondary) }
                }
                .padding(.vertical, 8)
            }

            GroupBox(label: Text("Clipboard History")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Maximum history size:")
                        Picker("", selection: $maxHistorySize) {
                            Text("25").tag(25); Text("50").tag(50); Text("100").tag(100); Text("200").tag(200)
                        }.frame(width: 100)
                    }
                    Text("Number of clipboard items to keep in history").font(.caption).foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Legacy Views (Kept for Compatibility)

struct ClipsSettingsView: View {
    @Binding var maxHistorySize: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("CLIPS SETTINGS").font(.headline)
            GroupBox(label: Text("History")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Maximum history size:")
                        Picker("", selection: $maxHistorySize) {
                            Text("25").tag(25); Text("50").tag(50); Text("100").tag(100); Text("200").tag(200)
                        }.frame(width: 100)
                    }
                    Text("Number of clipboard items to keep in history").font(.caption).foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SnippetsSettingsView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("SNIPPETS SETTINGS").font(.headline)
            GroupBox(label: Text("Statistics")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack { Text("Total snippets:"); Spacer(); Text("\(clipboardManager.snippets.count)").foregroundColor(.secondary) }
                    HStack { Text("Total folders:"); Spacer(); Text("\(clipboardManager.folders.count)").foregroundColor(.secondary) }
                    HStack { Text("Favorite snippets:"); Spacer(); Text("\(clipboardManager.snippets.filter { $0.isFavorite }.count)").foregroundColor(.secondary) }
                }
                .padding(.vertical, 8)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

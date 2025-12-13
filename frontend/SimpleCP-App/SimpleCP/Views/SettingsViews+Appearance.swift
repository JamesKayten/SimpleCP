//  SettingsViews+Appearance.swift - Appearance settings tab

import SwiftUI

// MARK: - Appearance Settings View

struct AppearanceSettingsView: View {
    @Binding var windowWidth: Int
    @Binding var windowHeight: Int
    @Binding var windowOpacity: Double
    @Binding var interfaceFont: String
    @Binding var interfaceFontSize: Double
    @Binding var clipFont: String
    @Binding var clipFontSize: Double

    @State private var opacityDebounceTask: Task<Void, Never>?
    @State private var lastAppliedOpacity: Double = 0.0
    @State private var hasAppeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            windowSizeGroup
            windowOpacityGroup
            fontsGroup
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            lastAppliedOpacity = windowOpacity
            hasAppeared = true
        }
        .onDisappear {
            opacityDebounceTask?.cancel()
            opacityDebounceTask = nil
            hasAppeared = false
        }
    }

    private var windowSizeGroup: some View {
        GroupBox(label: Text("Window Size")) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Width:").frame(width: 50, alignment: .leading)
                    Slider(value: Binding(get: { Double(windowWidth) }, set: { windowWidth = Int($0) }), in: 250...800, step: 10)
                        .onChange(of: windowWidth) { newValue in
                            guard hasAppeared else { return }
                            MenuBarManager.shared.updateWindowSize(width: newValue, height: windowHeight)
                        }
                    Text("\(windowWidth)px").font(.system(.body, design: .monospaced)).foregroundColor(.secondary).frame(width: 60, alignment: .trailing)
                }
                HStack {
                    Text("Height:").frame(width: 50, alignment: .leading)
                    Slider(value: Binding(get: { Double(windowHeight) }, set: { windowHeight = Int($0) }), in: 300...800, step: 10)
                        .onChange(of: windowHeight) { newValue in
                            guard hasAppeared else { return }
                            MenuBarManager.shared.updateWindowSize(width: windowWidth, height: newValue)
                        }
                    Text("\(windowHeight)px").font(.system(.body, design: .monospaced)).foregroundColor(.secondary).frame(width: 60, alignment: .trailing)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var windowOpacityGroup: some View {
        GroupBox(label: Text("Window Opacity")) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("90%").font(.caption).foregroundColor(.secondary).frame(width: 35, alignment: .leading)
                    Slider(value: $windowOpacity, in: 0.90...1.0, step: 0.01) { Text("Opacity") }
                        .onChange(of: windowOpacity) { newValue in
                            guard hasAppeared else { return }
                            opacityDebounceTask?.cancel()
                            opacityDebounceTask = Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 100_000_000)
                                guard !Task.isCancelled else { return }
                                applyOpacityToMainWindow(newValue)
                            }
                        }
                    Text("100%").font(.caption).foregroundColor(.secondary).frame(width: 35, alignment: .trailing)
                }
                Text("\(Int(windowOpacity * 100))% - Changes apply immediately").font(.caption).foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
    }

    private var fontsGroup: some View {
        GroupBox(label: Text("Fonts")) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Interface:")
                    Picker("", selection: $interfaceFont) {
                        Text("SF Pro").tag("SF Pro")
                        Text("SF Mono").tag("SF Mono")
                        Text("Helvetica").tag("Helvetica")
                    }.frame(width: 150)
                    Text("Size:")
                    Picker("", selection: $interfaceFontSize) {
                        ForEach([11.0, 12.0, 13.0, 14.0, 15.0], id: \.self) { Text("\(Int($0))").tag($0) }
                    }.frame(width: 70)
                }
                HStack {
                    Text("Clips:")
                    Picker("", selection: $clipFont) {
                        Text("SF Mono").tag("SF Mono")
                        Text("Menlo").tag("Menlo")
                        Text("Monaco").tag("Monaco")
                    }.frame(width: 150)
                    Text("Size:")
                    Picker("", selection: $clipFontSize) {
                        ForEach([10.0, 11.0, 12.0, 13.0, 14.0], id: \.self) { Text("\(Int($0))").tag($0) }
                    }.frame(width: 70)
                }
                Text("Interface font affects labels and UI elements. Clip font affects clipboard content display.")
                    .font(.caption).foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
    }

    private func applyOpacityToMainWindow(_ opacity: Double) {
        guard abs(lastAppliedOpacity - opacity) > 0.001 else { return }
        guard MenuBarManager.shared.isWindowVisible() else { return }
        lastAppliedOpacity = opacity
        MenuBarManager.shared.updatePopoverOpacity(opacity)
    }
}

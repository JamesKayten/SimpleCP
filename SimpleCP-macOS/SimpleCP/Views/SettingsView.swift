import SwiftUI

struct SettingsView: View {
    @State private var monitoringEnabled = true
    @State private var maxHistoryItems = 50
    @State private var autoStartEnabled = true
    @State private var showNotifications = false

    var body: some View {
        Form {
            Section("Clipboard Monitoring") {
                Toggle("Enable clipboard monitoring", isOn: $monitoringEnabled)
                    .help("Automatically capture clipboard changes")

                HStack {
                    Text("Max history items:")
                    Spacer()
                    TextField("Count", value: $maxHistoryItems, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                .help("Maximum number of items to keep in history")
            }

            Section("Application") {
                Toggle("Launch at login", isOn: $autoStartEnabled)
                    .help("Start SimpleCP automatically when you log in")

                Toggle("Show notifications", isOn: $showNotifications)
                    .help("Show system notifications for clipboard events")
            }

            Section("Backend Connection") {
                BackendStatusView()
            }

            Section("About") {
                AboutView()
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .frame(maxWidth: 500)
    }
}

struct BackendStatusView: View {
    @State private var backendStatus: String = "Checking..."
    @State private var isConnected = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)

                Text("Backend Status: \(backendStatus)")
                    .font(.body)

                Spacer()

                Button("Check Connection") {
                    checkBackendStatus()
                }
            }

            Text("Backend URL: http://127.0.0.1:8080")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onAppear {
            checkBackendStatus()
        }
    }

    private func checkBackendStatus() {
        Task {
            let apiClient = APIClient()
            do {
                _ = try await apiClient.getStatus()
                await MainActor.run {
                    backendStatus = "Connected"
                    isConnected = true
                }
            } catch {
                await MainActor.run {
                    backendStatus = "Disconnected"
                    isConnected = false
                }
            }
        }
    }
}

struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SimpleCP")
                .font(.title2)
                .fontWeight(.bold)

            Text("Version 1.0.0")
                .font(.body)
                .foregroundColor(.secondary)

            Text("Multi-store clipboard manager with history and snippets")
                .font(.body)
                .foregroundColor(.secondary)

            HStack {
                Link("GitHub", destination: URL(string: "https://github.com/JamesKayten/SimpleCP")!)

                Text("•")
                    .foregroundColor(.secondary)

                Link("Documentation", destination: URL(string: "https://github.com/JamesKayten/SimpleCP#readme")!)
            }
            .font(.body)
        }
    }
}

#Preview {
    SettingsView()
}
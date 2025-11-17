//
//  SettingsView.swift
//  SimpleCPApp
//
//  Application settings window
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("refreshInterval") private var refreshInterval: Double = 5.0
    @AppStorage("showNotifications") private var showNotifications: Bool = true

    var body: some View {
        TabView {
            // General settings
            Form {
                Section("Backend Connection") {
                    LabeledContent("API Base URL") {
                        Text(appState.apiClient.baseURL)
                            .textSelection(.enabled)
                    }

                    LabeledContent("Status") {
                        HStack {
                            Circle()
                                .fill(appState.apiClient.isConnected ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(appState.apiClient.isConnected ? "Connected" : "Disconnected")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button("Check Connection") {
                        Task {
                            do {
                                _ = try await appState.apiClient.checkHealth()
                                appState.apiClient.isConnected = true
                            } catch {
                                appState.apiClient.isConnected = false
                                appState.errorMessage = "Connection failed: \(error.localizedDescription)"
                            }
                        }
                    }
                }

                Section("Refresh") {
                    Slider(value: $refreshInterval, in: 1...30, step: 1) {
                        Text("Auto-refresh interval: \(Int(refreshInterval))s")
                    }
                }

                Section("Notifications") {
                    Toggle("Show notifications", isOn: $showNotifications)
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("General", systemImage: "gearshape")
            }

            // About
            Form {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.on.clipboard.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.accentColor)

                        Text("SimpleCP")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Version 1.0.0")
                            .foregroundColor(.secondary)

                        Text("A modern clipboard manager for macOS")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
        .frame(width: 500, height: 400)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}

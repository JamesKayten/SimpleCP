import SwiftUI

// Settings window
struct SettingsWindow: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var apiClient: APIClient
    @State private var healthStatus: HealthStatus?
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.title)
                .fontWeight(.bold)

            Divider()

            // Backend Status
            GroupBox(label: Text("Backend Status")) {
                VStack(alignment: .leading, spacing: 8) {
                    if let health = healthStatus {
                        HStack {
                            Text("Status:")
                            Text(health.status)
                                .foregroundColor(.green)
                                .fontWeight(.semibold)
                        }

                        HStack {
                            Text("History Items:")
                            Text("\(health.historyCount)")
                        }

                        HStack {
                            Text("Snippet Folders:")
                            Text("\(health.snippetFolders)")
                        }
                    } else if isLoading {
                        ProgressView()
                    } else {
                        Text("Not connected")
                            .foregroundColor(.red)
                    }

                    Button("Check Connection") {
                        Task {
                            await checkHealth()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }

            // API Configuration
            GroupBox(label: Text("API Configuration")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Base URL:")
                        Text(Constants.apiBaseURL)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Timeout:")
                        Text("\(Int(Constants.apiTimeout))s")
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }

            Spacer()

            HStack {
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400, height: 400)
        .onAppear {
            Task {
                await checkHealth()
            }
        }
    }

    private func checkHealth() async {
        isLoading = true
        do {
            healthStatus = try await apiClient.getHealth()
        } catch {
            healthStatus = nil
        }
        isLoading = false
    }
}

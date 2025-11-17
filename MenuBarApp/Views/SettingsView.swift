import SwiftUI

struct SettingsView: View {
    let apiClient: SimpleCPAPIClient

    @State private var maxHistoryItems: Int = 50
    @State private var privacyModeEnabled: Bool = false
    @State private var excludedApps: [String] = []
    @State private var newAppName: String = ""
    @State private var analyticsEnabled: Bool = true
    @State private var isLoading: Bool = true

    var body: some View {
        TabView {
            // General Settings
            generalSettingsView
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            // Privacy Settings
            privacySettingsView
                .tabItem {
                    Label("Privacy", systemImage: "hand.raised")
                }

            // Analytics Settings
            analyticsSettingsView
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar")
                }

            // About
            aboutView
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .padding()
        .frame(width: 600, height: 400)
        .onAppear {
            loadSettings()
        }
    }

    var generalSettingsView: some View {
        Form {
            Section(header: Text("History").font(.headline)) {
                HStack {
                    Text("Maximum history items:")
                    Spacer()
                    TextField("50", value: $maxHistoryItems, formatter: NumberFormatter())
                        .frame(width: 100)
                        .onChange(of: maxHistoryItems) { _ in
                            updateHistorySettings()
                        }
                }

                Text("Higher values use more memory")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Reset to Defaults") {
                resetSettings()
            }
        }
        .padding()
    }

    var privacySettingsView: some View {
        Form {
            Section(header: Text("Privacy Mode").font(.headline)) {
                Toggle("Enable Privacy Mode", isOn: $privacyModeEnabled)
                    .onChange(of: privacyModeEnabled) { _ in
                        updatePrivacyMode()
                    }

                Text("When enabled, clipboard tracking is completely disabled")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section(header: Text("Excluded Applications").font(.headline)) {
                Text("Clipboard content from these apps will not be tracked")
                    .font(.caption)
                    .foregroundColor(.secondary)

                List {
                    ForEach(excludedApps, id: \.self) { app in
                        HStack {
                            Text(app)
                            Spacer()
                            Button(action: { removeExcludedApp(app) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                HStack {
                    TextField("Add application name...", text: $newAppName)
                    Button("Add") {
                        addExcludedApp()
                    }
                    .disabled(newAppName.isEmpty)
                }
            }
        }
        .padding()
    }

    var analyticsSettingsView: some View {
        Form {
            Section(header: Text("Usage Analytics").font(.headline)) {
                Toggle("Enable Analytics", isOn: $analyticsEnabled)
                    .onChange(of: analyticsEnabled) { _ in
                        updateAnalyticsSettings()
                    }

                Text("Track usage patterns to show insights about your clipboard activity")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section(header: Text("Data Management").font(.headline)) {
                Button("View Analytics Dashboard") {
                    openAnalyticsDashboard()
                }

                Button("Clear Analytics Data", role: .destructive) {
                    clearAnalytics()
                }
            }
        }
        .padding()
    }

    var aboutView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.on.clipboard.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            Text("SimpleCP")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Advanced Clipboard Manager")
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(icon: "clock.arrow.circlepath", text: "Unlimited clipboard history")
                FeatureRow(icon: "folder", text: "Organized snippets")
                FeatureRow(icon: "magnifyingglass", text: "Powerful search")
                FeatureRow(icon: "chart.bar", text: "Usage analytics")
                FeatureRow(icon: "lock.shield", text: "Privacy protection")
            }

            Spacer()

            Text("Version 1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Functions

    func loadSettings() {
        Task {
            do {
                let settings = try await apiClient.getSettings()

                await MainActor.run {
                    if let history = settings["history"] as? [String: Any],
                       let maxItems = history["max_items"] as? Int {
                        maxHistoryItems = maxItems
                    }

                    if let privacy = settings["privacy"] as? [String: Any] {
                        privacyModeEnabled = privacy["privacy_mode"] as? Bool ?? false
                        excludedApps = privacy["excluded_apps"] as? [String] ?? []
                    }

                    if let analytics = settings["analytics"] as? [String: Any] {
                        analyticsEnabled = analytics["enabled"] as? Bool ?? true
                    }

                    isLoading = false
                }
            } catch {
                print("Failed to load settings: \(error)")
            }
        }
    }

    func updateHistorySettings() {
        Task {
            do {
                let updates: [String: Any] = ["max_items": maxHistoryItems]
                try await apiClient.updateSettingsSection(section: "history", updates: updates)
            } catch {
                print("Failed to update history settings: \(error)")
            }
        }
    }

    func updatePrivacyMode() {
        Task {
            do {
                let updates: [String: Any] = ["privacy_mode": privacyModeEnabled]
                try await apiClient.updateSettingsSection(section: "privacy", updates: updates)
            } catch {
                print("Failed to update privacy mode: \(error)")
            }
        }
    }

    func updateAnalyticsSettings() {
        Task {
            do {
                let updates: [String: Any] = ["enabled": analyticsEnabled]
                try await apiClient.updateSettingsSection(section: "analytics", updates: updates)
            } catch {
                print("Failed to update analytics settings: \(error)")
            }
        }
    }

    func addExcludedApp() {
        guard !newAppName.isEmpty else { return }

        excludedApps.append(newAppName)
        newAppName = ""

        Task {
            do {
                let updates: [String: Any] = ["excluded_apps": excludedApps]
                try await apiClient.updateSettingsSection(section: "privacy", updates: updates)
            } catch {
                print("Failed to add excluded app: \(error)")
            }
        }
    }

    func removeExcludedApp(_ app: String) {
        excludedApps.removeAll { $0 == app }

        Task {
            do {
                let updates: [String: Any] = ["excluded_apps": excludedApps]
                try await apiClient.updateSettingsSection(section: "privacy", updates: updates)
            } catch {
                print("Failed to remove excluded app: \(error)")
            }
        }
    }

    func resetSettings() {
        // TODO: Implement reset to defaults
    }

    func openAnalyticsDashboard() {
        // TODO: Open analytics dashboard
    }

    func clearAnalytics() {
        let alert = NSAlert()
        alert.messageText = "Clear Analytics Data?"
        alert.informativeText = "This will delete all usage analytics. This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            Task {
                // TODO: Call API to clear analytics
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            Text(text)
        }
    }
}

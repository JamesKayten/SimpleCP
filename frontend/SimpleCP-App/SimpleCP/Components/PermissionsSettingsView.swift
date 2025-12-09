//
//  PermissionsSettingsView.swift
//  SimpleCP
//
//  Settings view for managing app permissions
//

import SwiftUI
import ApplicationServices

struct PermissionsSettingsView: View {
    @ObservedObject private var permissionMonitor = AccessibilityPermissionMonitor.shared
    @Environment(\.fontPreferences) private var fontPrefs
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PERMISSIONS")
                .font(fontPrefs.interfaceFont(weight: .semibold))
                .foregroundColor(.secondary)
            
            // Accessibility Permission
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Image(systemName: permissionMonitor.isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(permissionMonitor.isGranted ? .green : .red)
                                        .font(.system(size: 16))
                                    
                                    Text("Accessibility Access")
                                        .font(fontPrefs.interfaceFont(weight: .medium))
                                }
                                
                                Text(permissionMonitor.isGranted ? "Granted" : "Not Granted")
                                    .font(fontPrefs.interfaceFont())
                                    .foregroundColor(permissionMonitor.isGranted ? .green : .red)
                            }
                            
                            Spacer()
                            
                            // Refresh button
                            Button(action: {
                                permissionMonitor.checkPermission()
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.plain)
                            .help("Refresh permission status")
                            
                            if !permissionMonitor.isGranted {
                                Button("Grant Permission") {
                                    AccessibilityPermissionManager.shared.requestPermission(from: nil) { _ in
                                        // Check immediately after attempting to grant
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            permissionMonitor.checkPermission()
                                        }
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            } else {
                                Button("Open Settings") {
                                    AccessibilityPermissionManager.shared.openAccessibilitySettings()
                                }
                            }
                        }
                        
                        // IMPORTANT: Restart prompt when permission appears to be granted but not detected
                        if !permissionMonitor.isGranted {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 14))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Already enabled in Settings?")
                                        .font(fontPrefs.interfaceFont(weight: .semibold))
                                        .foregroundColor(.primary)
                                    Text("macOS requires an app restart to recognize permission changes")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("Quit App (Restart Required)") {
                                    // Just quit - user will manually reopen
                                    NSApp.terminate(nil)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.orange)
                                .controlSize(.regular)
                                .help("Quit SimpleCP - then reopen it from Applications")
                            }
                            .padding(12)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(8)
                            .padding(.top, 12)
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What This Enables:")
                            .font(fontPrefs.interfaceFont(weight: .medium))
                            .foregroundColor(.secondary)
                        
                        FeatureListItem(
                            icon: "command",
                            title: "Paste Immediately",
                            description: "Automatically paste clips to active app",
                            enabled: permissionMonitor.isGranted
                        )
                        
                        FeatureListItem(
                            icon: "keyboard",
                            title: "Keyboard Simulation",
                            description: "Simulate Cmd+V keypress programmatically",
                            enabled: permissionMonitor.isGranted
                        )
                    }
                    
                    Divider()
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How to Grant Permission:")
                            .font(fontPrefs.interfaceFont(weight: .medium))
                            .foregroundColor(.secondary)
                        
                        InstructionStep(number: 1, text: "Click \"Grant Permission\" above")
                        InstructionStep(number: 2, text: "System Settings will open to Privacy & Security → Accessibility")
                        InstructionStep(number: 3, text: "Find \"SimpleCP\" in the list and toggle the switch ON")
                        InstructionStep(number: 4, text: "Click \"Restart Now\" button (appears automatically)")
                        
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 12))
                            Text("Important: Restart is REQUIRED - macOS won't recognize the permission until SimpleCP restarts")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.orange)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 4)
                    }
                    
                    Divider()
                    
                    // Additional info
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Optional Feature")
                                .font(fontPrefs.interfaceFont(weight: .medium))
                            Text("You can still copy clips normally without this permission. Only the \"Paste Immediately\" feature requires Accessibility access.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                }
                .padding(12)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .onAppear {
            permissionMonitor.checkPermission()
        }
    }
}

struct FeatureListItem: View {
    let icon: String
    let title: String
    let description: String
    let enabled: Bool
    @Environment(\.fontPreferences) private var fontPrefs
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon on the left
            Image(systemName: icon)
                .foregroundColor(enabled ? .green : .secondary)
                .frame(width: 24, height: 24)
                .font(.system(size: 14))
            
            // Text content
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(fontPrefs.interfaceFont(weight: .medium))
                    .foregroundColor(.primary)
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            // Status badge (NOT a button - make this clear)
            HStack(spacing: 4) {
                Image(systemName: enabled ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                Text(enabled ? "Ready" : "Disabled")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(enabled ? .green : .orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(enabled ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
            )
        }
        .padding(.vertical, 4)
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String
    @Environment(\.fontPreferences) private var fontPrefs
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .font(fontPrefs.interfaceFont(weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 20, alignment: .trailing)
            
            Text(text)
                .font(fontPrefs.interfaceFont())
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

#Preview {
    PermissionsSettingsView()
        .frame(width: 600, height: 500)
}

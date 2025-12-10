//
//  AccessibilityStatusBanner.swift
//  SimpleCP
//
//  Shows a banner when Accessibility permissions are not granted
//

import SwiftUI
import ApplicationServices

struct AccessibilityStatusBanner: View {
    @ObservedObject private var permissionMonitor = AccessibilityPermissionMonitor.shared
    @Environment(\.fontPreferences) private var fontPrefs
    
    var body: some View {
        if !permissionMonitor.isGranted && !permissionMonitor.isDismissed {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 14))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Accessibility Permission Required")
                        .font(fontPrefs.interfaceFont(weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Enable \"Paste Immediately\" feature (restart required after enabling)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Restart App") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Restart SimpleCP to detect permission changes")
                
                Button("Enable") {
                    AccessibilityPermissionManager.shared.requestPermission(from: NSApp.keyWindow) { granted in
                        if granted {
                            permissionMonitor.checkPermission()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button(action: {
                    permissionMonitor.dismissBanner()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .help("Dismiss (if you've already enabled)")
            }
            .padding(12)
            .background(Color.orange.opacity(0.15))
            .cornerRadius(8)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: permissionMonitor.isGranted)
        }
    }
}

/// Monitors accessibility permission status and provides reactive updates
@MainActor
class AccessibilityPermissionMonitor: ObservableObject {
    static let shared = AccessibilityPermissionMonitor()
    
    @Published var isGranted: Bool = false
    @Published var isDismissed: Bool = false
    
    private var timer: Timer?
    private let dismissedKey = "accessibilityBannerDismissed"
    
    private init() {
        checkPermission()
        loadDismissedState()
        startMonitoring()
    }
    
    func checkPermission() {
        let wasGranted = isGranted

        // ONLY trust AXIsProcessTrusted() - don't cache permission state
        // Caching caused issues when rebuilding (code signature changes invalidate permission)
        isGranted = AXIsProcessTrusted()

        // If permission was just granted, reset dismissed state
        if !wasGranted && isGranted {
            isDismissed = false
            UserDefaults.standard.removeObject(forKey: dismissedKey)
            print("✅ Accessibility permission granted!")
        } else if wasGranted && !isGranted {
            print("❌ Accessibility permission revoked or invalidated!")
        }
    }
    
    func startMonitoring() {
        // Check every 2 seconds for permission changes
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkPermission()
        }
    }
    
    func dismissBanner() {
        isDismissed = true
        UserDefaults.standard.set(true, forKey: dismissedKey)
        print("ℹ️ Accessibility banner dismissed for this session")
    }
    
    private func loadDismissedState() {
        // Only load dismissed state if permission is still not granted
        if !isGranted {
            isDismissed = UserDefaults.standard.bool(forKey: dismissedKey)
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}

#Preview {
    VStack {
        AccessibilityStatusBanner()
        Spacer()
    }
    .frame(width: 400, height: 200)
}

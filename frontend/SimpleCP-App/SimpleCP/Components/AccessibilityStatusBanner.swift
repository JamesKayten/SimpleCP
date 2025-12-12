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
                        Task { @MainActor in
                            if granted {
                                permissionMonitor.checkPermission()
                            }
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

        // Use AXIsProcessTrustedWithOptions as a more reliable check
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        let axTrusted = AXIsProcessTrustedWithOptions(options)
        
        // Also check if we've successfully pasted before (stored flag)
        let hasWorkedBefore = UserDefaults.standard.bool(forKey: "accessibilityHasWorked")

        // Trust either the API or our own successful paste history
        isGranted = axTrusted || hasWorkedBefore
        
        // Enhanced debug logging
        if !axTrusted && !hasWorkedBefore {
            print("⚠️ Accessibility not granted: AXTrusted=\(axTrusted), hasWorked=\(hasWorkedBefore)")
            debugAccessibilityPermission()
        }

        // If permission was just granted, reset dismissed state
        if !wasGranted && isGranted {
            isDismissed = false
            UserDefaults.standard.removeObject(forKey: dismissedKey)
            print("✅ Accessibility permission granted!")
        } else if wasGranted && !isGranted {
            print("❌ Accessibility permission revoked!")
        }
    }
    
    /// Detailed debugging information about accessibility permissions
    private func debugAccessibilityPermission() {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔍 ACCESSIBILITY PERMISSION DEBUG INFO")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // App information
        if let bundleId = Bundle.main.bundleIdentifier {
            print("📦 Bundle ID: \(bundleId)")
        } else {
            print("❌ No Bundle ID found!")
        }
        
        if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String {
            print("📱 App Name: \(appName)")
        }
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            print("🔢 Version: \(version)")
        }
        
        // Executable path
        if let executablePath = Bundle.main.executablePath {
            print("📂 Executable Path: \(executablePath)")
            
            // Check if it's a dev build or archived
            if executablePath.contains("DerivedData") {
                print("⚠️ Running from Xcode (DerivedData)")
            } else if executablePath.contains(".app/Contents/MacOS/") {
                print("✅ Running from .app bundle")
            }
        }
        
        // Code signing info
        let secCode = getCodeSigningInfo()
        print("🔐 Code Signing: \(secCode)")
        
        // Process info
        let processId = ProcessInfo.processInfo.processIdentifier
        print("🔢 Process ID: \(processId)")
        
        // Check different AX APIs
        let axBasic = AXIsProcessTrusted()
        print("🔓 AXIsProcessTrusted(): \(axBasic)")
        
        let optionsNoPrompt = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        let axWithOptions = AXIsProcessTrustedWithOptions(optionsNoPrompt)
        print("🔓 AXIsProcessTrustedWithOptions(noPrompt): \(axWithOptions)")
        
        // Test actual accessibility API
        print("🧪 Testing actual accessibility API...")
        testAccessibilityAPI()
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("💡 TROUBLESHOOTING STEPS:")
        print("1. Open System Settings > Privacy & Security > Accessibility")
        if let bundleId = Bundle.main.bundleIdentifier {
            print("2. Look for '\(bundleId)' or your app name")
        }
        print("3. Toggle the permission OFF and back ON")
        print("4. Completely QUIT this app (Cmd+Q) and relaunch")
        print("5. If the app is archived, ensure it's properly code-signed")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
    
    /// Get code signing information
    private func getCodeSigningInfo() -> String {
        var code: SecCode?
        var status = SecCodeCopySelf([], &code)
        
        guard status == errSecSuccess, let code = code else {
            return "Unable to get code object (status: \(status))"
        }
        
        // Convert SecCode to SecStaticCode
        var staticCode: SecStaticCode?
        status = SecCodeCopyStaticCode(code, [], &staticCode)
        
        guard status == errSecSuccess, let staticCode = staticCode else {
            return "Unable to get static code (status: \(status))"
        }
        
        var dynamicCodeInfo: CFDictionary?
        status = SecCodeCopySigningInformation(staticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &dynamicCodeInfo)
        
        guard status == errSecSuccess else {
            return "Unable to get signing info (status: \(status))"
        }
        
        if let info = dynamicCodeInfo as? [String: Any] {
            if let identifier = info[kSecCodeInfoIdentifier as String] as? String {
                let isSigned = info[kSecCodeInfoFormat as String] != nil
                return isSigned ? "Signed (\(identifier))" : "Not signed (\(identifier))"
            }
        }
        
        return "Signed (no identifier)"
    }
    
    /// Test if accessibility API actually works
    private func testAccessibilityAPI() {
        // Try to get the list of running applications via accessibility API
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        
        // Try to create an accessibility element for the system-wide element
        let systemWideElement = AXUIElementCreateSystemWide()
        
        var focusedApp: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedApplicationAttribute as CFString, &focusedApp)
        
        if result == .success {
            print("✅ Successfully accessed focused application via AX API")
            if let app = focusedApp {
                var appName: CFTypeRef?
                let nameResult = AXUIElementCopyAttributeValue(app as! AXUIElement, kAXTitleAttribute as CFString, &appName)
                if nameResult == .success, let name = appName as? String {
                    print("   Focused app: \(name)")
                }
            }
        } else {
            print("❌ Failed to access AX API: \(result.rawValue)")
            print("   Error codes: -25200 = permission denied, -25204 = invalid element")
            
            if result.rawValue == -25200 {
                print("   → This confirms accessibility permission is NOT granted")
            }
        }
    }

    /// Call this when a paste operation succeeds to mark permission as working
    func markPermissionAsWorking() {
        UserDefaults.standard.set(true, forKey: "accessibilityHasWorked")
        if !isGranted {
            isGranted = true
            isDismissed = false
            print("✅ Accessibility permission marked as working (paste succeeded)")
        }
    }

    /// Reset the "has worked" flag (e.g., when user revokes permission)
    func resetWorkingFlag() {
        UserDefaults.standard.removeObject(forKey: "accessibilityHasWorked")
    }
    
    func startMonitoring() {
        // Check every 2 seconds for permission changes
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPermission()
            }
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

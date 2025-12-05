//
//  FontPreferences.swift
//  SimpleCP
//
//  Font preference management for consistent styling across the app
//

import SwiftUI

// MARK: - Font Preferences Model

struct FontPreferences {
    var interfaceFont: String
    var interfaceFontSize: Double
    var clipFont: String
    var clipFontSize: Double
    
    static let `default` = FontPreferences(
        interfaceFont: "SF Pro",
        interfaceFontSize: 13.0,
        clipFont: "SF Mono",
        clipFontSize: 12.0
    )
    
    // Helper to get NSFont for interface elements
    func interfaceNSFont(weight: NSFont.Weight = .regular) -> NSFont {
        let fontName: String
        switch interfaceFont {
        case "SF Mono":
            fontName = "SFMono-Regular"
        case "Helvetica":
            fontName = "Helvetica"
        default: // "SF Pro"
            fontName = ".AppleSystemUIFont"
        }
        
        if let font = NSFont(name: fontName, size: interfaceFontSize) {
            return font
        }
        return NSFont.systemFont(ofSize: interfaceFontSize, weight: weight)
    }
    
    // Helper to get Font for SwiftUI interface elements
    func interfaceFont(weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        switch interfaceFont {
        case "SF Mono":
            return .system(size: interfaceFontSize, weight: weight, design: .monospaced)
        case "Helvetica":
            return .custom("Helvetica", size: interfaceFontSize)
        default: // "SF Pro"
            return .system(size: interfaceFontSize, weight: weight, design: design)
        }
    }
    
    // Helper to get Font for clip content
    func clipContentFont() -> Font {
        switch clipFont {
        case "Menlo":
            return .custom("Menlo", size: clipFontSize)
        case "Monaco":
            return .custom("Monaco", size: clipFontSize)
        default: // "SF Mono"
            return .system(size: clipFontSize, design: .monospaced)
        }
    }
}

// MARK: - Environment Key

private struct FontPreferencesKey: EnvironmentKey {
    static let defaultValue = FontPreferences.default
}

extension EnvironmentValues {
    var fontPreferences: FontPreferences {
        get { self[FontPreferencesKey.self] }
        set { self[FontPreferencesKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    func fontPreferences(_ preferences: FontPreferences) -> some View {
        environment(\.fontPreferences, preferences)
    }
}

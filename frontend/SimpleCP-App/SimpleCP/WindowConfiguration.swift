//
//  WindowConfiguration.swift
//  SimpleCP
//
//  Created by SimpleCP
//

import Foundation
import CoreGraphics

/// Single source of truth for window dimensions across the app
enum WindowConfiguration {
    
    /// Get window dimensions for a given size preference
    static func dimensions(for size: String) -> (width: CGFloat, height: CGFloat) {
        switch size {
        case "compact":
            return (400, 450)
        case "normal":
            return (450, 500)
        case "large":
            return (550, 650)
        default:
            return (450, 500) // fallback to normal
        }
    }
    
    /// Get current window dimensions based on UserDefaults
    static var currentDimensions: (width: CGFloat, height: CGFloat) {
        let windowSizePreference = UserDefaults.standard.string(forKey: "windowSize") ?? "compact"
        return dimensions(for: windowSizePreference)
    }
}

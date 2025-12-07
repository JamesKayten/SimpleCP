import Foundation
import CoreGraphics

enum AppConstants {
    static let defaultRefreshInterval: TimeInterval = 2.0
    static let defaultMaxHistoryItems = 100

    /// Backend port (derived from "SimpleCP" ASCII sum: 49152 + 765 = 49917)
    static let backendPort = 49917

    enum UserDefaultsKeys {
        static let autoRefreshInterval = "autoRefreshInterval"
        static let maxHistoryItems = "maxHistoryItems"
        static let windowSize = "windowSize"
        static let backendPort = "backendPort"
    }

    enum ContentTypes {
        static let text = "text"
        static let url = "url"
        static let email = "email"
        static let code = "code"
    }

    enum ItemTypes {
        static let history = "history"
        static let snippet = "snippet"
    }
}

// MARK: - Window Size Configuration
/// Single source of truth for window dimensions
enum WindowSizeConfig: String, CaseIterable {
    case compact = "compact"
    case normal = "normal"
    case large = "large"

    var dimensions: (width: CGFloat, height: CGFloat) {
        switch self {
        case .compact:
            return (400, 450)
        case .normal:
            return (450, 500)
        case .large:
            return (550, 650)
        }
    }

    var width: CGFloat { dimensions.width }
    var height: CGFloat { dimensions.height }

    static func from(_ string: String) -> WindowSizeConfig {
        WindowSizeConfig(rawValue: string) ?? .compact
    }
}

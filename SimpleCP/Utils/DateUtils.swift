import Foundation

// Date formatting utilities
struct DateUtils {
    // Format timestamp for display
    static func formatTimestamp(_ date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current

        // If today, show time only
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            return formatter.string(from: date)
        }

        // If yesterday
        if calendar.isDateInYesterday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            return "Yesterday \(formatter.string(from: date))"
        }

        // If this week, show day name
        if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now),
           date > weekAgo {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE HH:mm"
            return formatter.string(from: date)
        }

        // Otherwise show full date
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // Format relative time (e.g., "2 minutes ago")
    static func formatRelativeTime(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
}

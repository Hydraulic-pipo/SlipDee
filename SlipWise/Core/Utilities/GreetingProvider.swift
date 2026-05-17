import Foundation

struct GreetingProvider {
    // Example expectations for unit-test-style checks:
    // 10:00 -> Good morning ☀️
    // 14:00 -> Good afternoon 🌤️
    // 18:00 -> Good evening 🌙
    // 23:00 -> Good night 🌙
    // 03:00 -> Good night 🌙
    static func greeting(
        for date: Date = Date(),
        calendar: Calendar = .current,
        displayName: String? = nil
    ) -> String {
        let hour = calendar.component(.hour, from: date)
        let baseGreeting: String
        let emoji: String

        switch hour {
        case 5..<12:
            baseGreeting = "Good morning"
            emoji = "☀️"
        case 12..<17:
            baseGreeting = "Good afternoon"
            emoji = "🌤️"
        case 17..<21:
            baseGreeting = "Good evening"
            emoji = "🌙"
        default:
            baseGreeting = "Good night"
            emoji = "🌙"
        }

        let trimmedName = displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if trimmedName.isEmpty {
            return "\(baseGreeting) \(emoji)"
        }

        return "\(baseGreeting), \(trimmedName) \(emoji)"
    }
}

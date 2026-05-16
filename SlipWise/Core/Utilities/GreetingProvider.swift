import Foundation

struct GreetingProvider {
    // Example expectations for unit-test-style checks:
    // 10:00 -> Good morning ☀️
    // 14:00 -> Good afternoon 🌤️
    // 18:00 -> Good evening 🌙
    // 23:00 -> Good night 🌙
    // 03:00 -> Good night 🌙
    static func greeting(for date: Date = Date(), calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: date)

        switch hour {
        case 5..<12:
            return "Good morning ☀️"
        case 12..<17:
            return "Good afternoon 🌤️"
        case 17..<21:
            return "Good evening 🌙"
        default:
            return "Good night 🌙"
        }
    }
}

import Foundation

struct MonthYearFormatter {
    static func displayName(
        month: Int,
        year: Int,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> String {
        var components = DateComponents()
        components.calendar = calendar
        components.year = year
        components.month = month
        components.day = 1

        guard let date = calendar.date(from: components) else {
            return "\(month)/\(year)"
        }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

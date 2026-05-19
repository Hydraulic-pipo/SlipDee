import Foundation

struct RecurringIncomeDateHelper {
    static func expectedDate(
        payDay: Int,
        month: Int,
        year: Int,
        calendar: Calendar = .current
    ) -> Date? {
        guard (1...12).contains(month) else { return nil }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        components.hour = 9

        guard let firstDayOfMonth = calendar.date(from: components),
              let dayRange = calendar.range(of: .day, in: .month, for: firstDayOfMonth)
        else {
            return nil
        }

        components.day = min(max(payDay, dayRange.lowerBound), dayRange.upperBound - 1)
        return calendar.date(from: components)
    }

    static func expectedDateTitle(
        payDay: Int,
        month: Int,
        year: Int,
        calendar: Calendar = .current
    ) -> String {
        guard let date = expectedDate(payDay: payDay, month: month, year: year, calendar: calendar) else {
            return "Expected this month"
        }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale.current
        formatter.dateFormat = "d MMM"
        return "Expected on \(formatter.string(from: date))"
    }
}

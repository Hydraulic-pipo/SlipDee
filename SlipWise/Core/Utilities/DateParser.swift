import Foundation

enum DateParser {
    static func extractDate(from text: String, timeText: String? = nil) -> Date? {
        if let slashDate = firstMatch(for: #"\b(\d{1,2}/\d{1,2}/\d{2,4})\b"#, in: text),
           let date = parseSlashOrDashDate(slashDate, timeText: timeText) {
            return date
        }

        if let dashDate = firstMatch(for: #"\b(\d{1,2}-\d{1,2}-\d{2,4})\b"#, in: text),
           let date = parseSlashOrDashDate(dashDate, timeText: timeText) {
            return date
        }

        if let englishDate = firstMatch(for: #"\b(\d{1,2}\s+[A-Za-z]{3,9}\s+\d{4})\b"#, in: text),
           let date = parseEnglishDate(englishDate, timeText: timeText) {
            return date
        }

        if let thaiDate = firstMatch(for: #"\b(\d{1,2}\s+[ก-๙\.]+\s+\d{4})\b"#, in: text),
           let date = parseThaiDate(thaiDate, timeText: timeText) {
            return date
        }

        return nil
    }

    static func extractTime(from text: String) -> String? {
        let patterns = [
            #"(?i)(?:time|เวลา)[^\d]{0,5}(\d{1,2}:\d{2}(?::\d{2})?)"#,
            #"\b(\d{1,2}:\d{2}(?::\d{2})?)\b"#
        ]

        for pattern in patterns {
            if let match = firstMatch(for: pattern, in: text) {
                return match
            }
        }

        return nil
    }

    private static func parseSlashOrDashDate(_ rawDate: String, timeText: String?) -> Date? {
        let cleaned = rawDate.replacingOccurrences(of: "-", with: "/")
        let components = cleaned.split(separator: "/").map(String.init)
        guard components.count == 3,
              let day = Int(components[0]),
              let month = Int(components[1]),
              let rawYear = Int(components[2]) else {
            return nil
        }

        return buildDate(day: day, month: month, year: normalizeYear(rawYear), timeText: timeText)
    }

    private static func parseEnglishDate(_ rawDate: String, timeText: String?) -> Date? {
        let parts = rawDate.split(separator: " ").map(String.init)
        guard parts.count == 3,
              let day = Int(parts[0]),
              let month = englishMonths[parts[1].lowercased()],
              let rawYear = Int(parts[2]) else {
            return nil
        }

        return buildDate(day: day, month: month, year: normalizeYear(rawYear), timeText: timeText)
    }

    private static func parseThaiDate(_ rawDate: String, timeText: String?) -> Date? {
        let parts = rawDate.split(separator: " ").map(String.init)
        guard parts.count == 3,
              let day = Int(parts[0]),
              let month = thaiMonths[parts[1].lowercased()],
              let rawYear = Int(parts[2]) else {
            return nil
        }

        return buildDate(day: day, month: month, year: normalizeYear(rawYear), timeText: timeText)
    }

    private static func buildDate(day: Int, month: Int, year: Int, timeText: String?) -> Date? {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = .current
        components.day = day
        components.month = month
        components.year = year

        if let timeText {
            let timeParts = timeText.split(separator: ":").compactMap { Int($0) }
            if timeParts.count >= 2 {
                components.hour = timeParts[0]
                components.minute = timeParts[1]
                components.second = timeParts.count > 2 ? timeParts[2] : 0
            }
        }

        return components.date
    }

    private static func normalizeYear(_ rawYear: Int) -> Int {
        if rawYear >= 2500 { return rawYear - 543 }
        if rawYear < 100 { return 2000 + rawYear }
        return rawYear
    }

    private static func firstMatch(for pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let nsRange = NSRange(text.startIndex..., in: text)
        guard
            let match = regex.firstMatch(in: text, options: [], range: nsRange),
            match.numberOfRanges > 1,
            let range = Range(match.range(at: 1), in: text)
        else {
            return nil
        }

        return String(text[range])
    }

    private static let englishMonths: [String: Int] = [
        "jan": 1, "january": 1,
        "feb": 2, "february": 2,
        "mar": 3, "march": 3,
        "apr": 4, "april": 4,
        "may": 5,
        "jun": 6, "june": 6,
        "jul": 7, "july": 7,
        "aug": 8, "august": 8,
        "sep": 9, "sept": 9, "september": 9,
        "oct": 10, "october": 10,
        "nov": 11, "november": 11,
        "dec": 12, "december": 12
    ]

    private static let thaiMonths: [String: Int] = [
        "ม.ค.": 1, "มกราคม": 1,
        "ก.พ.": 2, "กุมภาพันธ์": 2,
        "มี.ค.": 3, "มีนาคม": 3,
        "เม.ย.": 4, "เมษายน": 4,
        "พ.ค.": 5, "พฤษภาคม": 5,
        "มิ.ย.": 6, "มิถุนายน": 6,
        "ก.ค.": 7, "กรกฎาคม": 7,
        "ส.ค.": 8, "สิงหาคม": 8,
        "ก.ย.": 9, "กันยายน": 9,
        "ต.ค.": 10, "ตุลาคม": 10,
        "พ.ย.": 11, "พฤศจิกายน": 11,
        "ธ.ค.": 12, "ธันวาคม": 12
    ]
}

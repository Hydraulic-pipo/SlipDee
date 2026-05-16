import Foundation

enum DateParsers {
    static let slipDateFormatters: [DateFormatter] = {
        let locales = [Locale(identifier: "en_US_POSIX"), Locale(identifier: "th_TH")]
        let formats = [
            "dd/MM/yyyy HH:mm",
            "d/M/yyyy HH:mm",
            "dd/MM/yy HH:mm",
            "d/M/yy HH:mm",
            "dd-MM-yyyy HH:mm",
            "d-M-yyyy HH:mm",
            "dd MMM yyyy HH:mm",
            "d MMM yyyy HH:mm"
        ]

        return locales.flatMap { locale in
            formats.map { format in
                let formatter = DateFormatter()
                formatter.locale = locale
                formatter.timeZone = .current
                formatter.dateFormat = format
                return formatter
            }
        }
    }()

    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

import Foundation

enum AmountParser {
    static func extractAmount(from text: String) -> Double? {
        let patterns = [
            #"(?i)฿\s*([\d,]+(?:\.\d{1,2})?)"#,
            #"(?i)\bTHB\s*([\d,]+(?:\.\d{1,2})?)"#,
            #"([\d,]+(?:\.\d{1,2})?)\s*บาท"#,
            #"(?i)(?:amount|total|จำนวนเงิน|ยอดเงิน|เงินโอน|จำนวน)[^\d]{0,10}([\d,]+(?:\.\d{1,2})?)"#
        ]

        for pattern in patterns {
            if let match = firstMatch(for: pattern, in: text), let amount = normalize(match) {
                return amount
            }
        }

        let fallback = text
            .replacingOccurrences(of: "\n", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .compactMap { normalize(String($0)) }
            .filter { $0 > 0 && $0 < 10_000_000 }
            .sorted(by: >)

        return fallback.first
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

    private static func normalize(_ rawValue: String) -> Double? {
        let cleaned = rawValue
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "฿", with: "")
            .replacingOccurrences(of: "THB", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return Double(cleaned)
    }
}

import Foundation

struct SlipParserService {
    private let supportedBanks: [BankDefinition] = [
        BankDefinition(canonicalName: "KBank", aliases: ["KBank", "Kasikorn", "Kasikornbank", "กสิกรไทย"]),
        BankDefinition(canonicalName: "SCB", aliases: ["SCB", "Siam Commercial Bank", "ไทยพาณิชย์"]),
        BankDefinition(canonicalName: "Bangkok Bank", aliases: ["Bangkok Bank", "Bualuang", "กรุงเทพ"]),
        BankDefinition(canonicalName: "Krungthai", aliases: ["Krungthai", "Krung Thai", "กรุงไทย"]),
        BankDefinition(canonicalName: "Krungsri", aliases: ["Krungsri", "Bay", "กรุงศรี"]),
        BankDefinition(canonicalName: "TTB", aliases: ["TTB", "ttb", "TMBThanachart", "ทหารไทยธนชาต"]),
        BankDefinition(canonicalName: "GSB", aliases: ["GSB", "Government Savings Bank", "ออมสิน"])
    ]

    func parse(textLines: [String]) -> ParsedSlip {
        // This parser stays intentionally heuristic-based: it is safe for local OCR drafts,
        // but users should still confirm the fields before saving.
        let normalizedLines = textLines.map(normalizeOCRLine(_:))
        let joinedText = normalizedLines.joined(separator: "\n")
        let amount = extractAmount(from: joinedText)
        let transactionTime = extractTime(from: joinedText)
        let date = extractDate(from: joinedText, timeText: transactionTime)
        let bankName = extractBankName(from: normalizedLines)
        let receiverName = extractPartyName(from: normalizedLines, labels: Self.receiverLabels)
        let senderName = extractPartyName(from: normalizedLines, labels: Self.senderLabels)
        let reference = extractReference(from: normalizedLines)
        let transferType = extractTransferType(from: normalizedLines)
        let type = inferTransactionType(from: textLines)
        let paymentMethod = inferPaymentMethod(from: transferType, lines: normalizedLines)
        let category = inferCategory(from: normalizedLines, type: type)

        return ParsedSlip(
            amount: amount,
            currencyCode: CurrencyCode.thb,
            type: type,
            paymentMethod: paymentMethod,
            categoryID: category.id,
            categoryName: category.name,
            categoryIconName: category.iconSystemName,
            bankName: bankName,
            receiverName: receiverName,
            senderName: senderName,
            transactionReference: reference,
            transactionDate: date,
            transactionTimeText: transactionTime,
            transferType: transferType,
            note: "",
            recognizedTextLines: normalizedLines,
            status: .parsed
        )
    }

    private func extractAmount(from text: String) -> Double? {
        let patterns = [
            #"(?i)฿\s*([\d,]+(?:\.\d{1,2})?)"#,
            #"(?i)\bTHB\s*([\d,]+(?:\.\d{1,2})?)"#,
            #"([\d,]+(?:\.\d{1,2})?)\s*บาท"#,
            #"(?i)(?:amount|total|จำนวนเงิน|ยอดเงิน|เงินโอน|จำนวน)[^\d]{0,10}([\d,]+(?:\.\d{1,2})?)"#
        ]

        for pattern in patterns {
            if let match = firstMatch(for: pattern, in: text, group: 1) {
                return normalizeAmount(match)
            }
        }

        let fallbackNumbers = text
            .replacingOccurrences(of: "\n", with: " ")
            .components(separatedBy: CharacterSet.whitespaces)
            .compactMap(normalizeAmount)
            .filter { $0 > 0 && $0 < 10_000_000 }
            .sorted(by: >)

        return fallbackNumbers.first
    }

    private func extractDate(from text: String, timeText: String?) -> Date? {
        if let slashDate = firstMatch(for: #"\b(\d{1,2}/\d{1,2}/\d{2,4})\b"#, in: text, group: 1),
           let date = parseSlashOrDashDate(slashDate, timeText: timeText) {
            return date
        }

        if let dashDate = firstMatch(for: #"\b(\d{1,2}-\d{1,2}-\d{2,4})\b"#, in: text, group: 1),
           let date = parseSlashOrDashDate(dashDate, timeText: timeText) {
            return date
        }

        if let englishDate = firstMatch(for: #"\b(\d{1,2}\s+[A-Za-z]{3,9}\s+\d{4})\b"#, in: text, group: 1),
           let date = parseEnglishDate(englishDate, timeText: timeText) {
            return date
        }

        if let thaiDate = firstMatch(for: #"\b(\d{1,2}\s+[ก-๙\.]+\s+\d{4})\b"#, in: text, group: 1),
           let date = parseThaiDate(thaiDate, timeText: timeText) {
            return date
        }

        return nil
    }

    private func extractTime(from text: String) -> String? {
        let patterns = [
            #"(?i)(?:time|เวลา)[^\d]{0,5}(\d{1,2}:\d{2}(?::\d{2})?)"#,
            #"\b(\d{1,2}:\d{2}(?::\d{2})?)\b"#
        ]

        for pattern in patterns {
            if let match = firstMatch(for: pattern, in: text, group: 1) {
                return match
            }
        }

        return nil
    }

    private func extractBankName(from lines: [String]) -> String? {
        for line in lines {
            if let bank = supportedBanks.first(where: { definition in
                definition.aliases.contains(where: { line.localizedCaseInsensitiveContains($0) })
            }) {
                return bank.canonicalName
            }
        }
        return nil
    }

    private func extractPartyName(from lines: [String], labels: [String]) -> String? {
        for (index, line) in lines.enumerated() {
            if labels.contains(where: { line.localizedCaseInsensitiveContains($0) }) {
                if let inlineName = extractValueAfterLabel(in: line, labels: labels),
                   isLikelyPersonOrMerchantName(inlineName) {
                    return inlineName
                }

                if lines.indices.contains(index + 1) {
                    let nextLine = cleanupNameCandidate(lines[index + 1])
                    if let nextLine, isLikelyPersonOrMerchantName(nextLine) {
                        return nextLine
                    }
                }
            }
        }

        return nil
    }

    private func extractReference(from lines: [String]) -> String? {
        let joinedText = lines.joined(separator: "\n")
        let patterns = [
            #"(?i)(?:ref(?:erence)?|transaction id|หมายเลขอ้างอิง|เลขที่รายการ|เลขอ้างอิง)[^\w]{0,8}([A-Z0-9\-]{6,30})"#,
            #"(?i)(?:ref(?:erence)?|transaction id|หมายเลขอ้างอิง|เลขที่รายการ|เลขอ้างอิง)[^\n]*?(\d{6,30})"#
        ]

        for pattern in patterns {
            if let value = firstMatch(for: pattern, in: joinedText, group: 1) {
                return value
            }
        }

        return nil
    }

    private func extractTransferType(from lines: [String]) -> String? {
        let knownTypes = [
            "พร้อมเพย์", "PromptPay",
            "โอนเงิน", "Transfer",
            "QR Payment", "สแกนจ่าย",
            "Bill Payment", "ชำระบิล"
        ]

        for line in lines {
            if let match = knownTypes.first(where: { line.localizedCaseInsensitiveContains($0) }) {
                return match
            }
        }

        return nil
    }

    private func inferTransactionType(from lines: [String]) -> TransactionType {
        let incomeKeywords = ["receive", "received", "deposit", "เงินเข้า", "รับเงิน", "incoming"]

        if lines.contains(where: { line in
            incomeKeywords.contains(where: { line.localizedCaseInsensitiveContains($0) })
        }) {
            return .income
        }

        return .expense
    }

    private func inferPaymentMethod(from transferType: String?, lines: [String]) -> PaymentMethod {
        let joinedText = lines.joined(separator: " ").lowercased()

        if transferType?.localizedCaseInsensitiveContains("promptpay") == true || joinedText.contains("promptpay") {
            return .promptPay
        }
        if transferType?.localizedCaseInsensitiveContains("qr") == true || joinedText.contains("qr payment") {
            return .qrPayment
        }
        if transferType?.localizedCaseInsensitiveContains("bill") == true || joinedText.contains("ชำระบิล") {
            return .billPayment
        }

        return .bankTransfer
    }

    private func inferCategory(from lines: [String], type: TransactionType) -> TransactionCategoryDefinition {
        if type == .income {
            return TransactionCategoryCatalog.definition(named: "Salary")
                ?? TransactionCategoryCatalog.defaultDefinitions[0]
        }

        let joinedText = lines.joined(separator: " ").lowercased()

        if joinedText.contains("grab") || joinedText.contains("taxi") || joinedText.contains("bts") {
            return TransactionCategoryCatalog.definition(named: "Transport")
                ?? TransactionCategoryCatalog.defaultDefinitions[0]
        }
        if joinedText.contains("coffee") || joinedText.contains("food") || joinedText.contains("cafe") {
            return TransactionCategoryCatalog.definition(named: "Food & Drink")
                ?? TransactionCategoryCatalog.defaultDefinitions[0]
        }
        if joinedText.contains("netflix") || joinedText.contains("movie") {
            return TransactionCategoryCatalog.definition(named: "Entertainment")
                ?? TransactionCategoryCatalog.defaultDefinitions[0]
        }
        if joinedText.contains("electric") || joinedText.contains("water bill") {
            return TransactionCategoryCatalog.definition(named: "Bills")
                ?? TransactionCategoryCatalog.defaultDefinitions[0]
        }

        return TransactionCategoryCatalog.definition(named: "Transfer")
            ?? TransactionCategoryCatalog.defaultDefinitions[0]
    }

    private func normalizeAmount(_ rawValue: String) -> Double? {
        let cleaned = rawValue
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "฿", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return Double(cleaned)
    }

    private func cleanupNameCandidate(_ value: String) -> String? {
        let separators = [":", "–"]
        let cleaned = separators.reduce(value) { partialResult, separator in
            partialResult.replacingOccurrences(of: separator, with: " ")
        }
        .replacingOccurrences(of: "  ", with: " ")
        .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else { return nil }
        return cleaned
    }

    private func normalizeOCRLine(_ line: String) -> String {
        line
            .replacingOccurrences(of: "TBH", with: "THB")
            .replacingOccurrences(of: "BHT", with: "THB")
            .replacingOccurrences(of: "|", with: " ")
            .replacingOccurrences(of: "—", with: "-")
            .replacingOccurrences(of: "•", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractValueAfterLabel(in line: String, labels: [String]) -> String? {
        for label in labels {
            guard let range = line.range(of: label, options: [.caseInsensitive]) else { continue }
            let suffix = line[range.upperBound...]
                .trimmingCharacters(in: CharacterSet(charactersIn: " :-"))

            if !suffix.isEmpty {
                return cleanupNameCandidate(String(suffix))
            }
        }

        return nil
    }

    private func isLikelyPersonOrMerchantName(_ value: String) -> Bool {
        guard value.count >= 3 else { return false }
        guard !value.containsDigit else { return false }

        let lowercased = value.lowercased()
        let disallowedTokens = [
            "บาท", "time", "date", "ref", "reference", "transaction", "bank", "จำนวนเงิน",
            "ยอดเงิน", "หมายเลข", "promptpay", "transfer", "qr payment"
        ]

        return !disallowedTokens.contains(where: { lowercased.contains($0) })
    }

    private func parseSlashOrDashDate(_ rawDate: String, timeText: String?) -> Date? {
        let cleaned = rawDate.replacingOccurrences(of: "-", with: "/")
        let components = cleaned.split(separator: "/").map(String.init)
        guard components.count == 3,
              let day = Int(components[0]),
              let month = Int(components[1]),
              let rawYear = Int(components[2]) else {
            return nil
        }

        let year = normalizeYear(rawYear)
        return buildDate(day: day, month: month, year: year, timeText: timeText)
    }

    private func parseEnglishDate(_ rawDate: String, timeText: String?) -> Date? {
        let parts = rawDate.split(separator: " ").map(String.init)
        guard parts.count == 3,
              let day = Int(parts[0]),
              let month = Self.englishMonths[parts[1].lowercased()],
              let rawYear = Int(parts[2]) else {
            return nil
        }

        return buildDate(day: day, month: month, year: normalizeYear(rawYear), timeText: timeText)
    }

    private func parseThaiDate(_ rawDate: String, timeText: String?) -> Date? {
        let parts = rawDate.split(separator: " ").map(String.init)
        guard parts.count == 3,
              let day = Int(parts[0]),
              let month = Self.thaiMonths[parts[1].lowercased()],
              let rawYear = Int(parts[2]) else {
            return nil
        }

        return buildDate(day: day, month: month, year: normalizeYear(rawYear), timeText: timeText)
    }

    private func buildDate(day: Int, month: Int, year: Int, timeText: String?) -> Date? {
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar(identifier: .gregorian)
        dateComponents.timeZone = .current
        dateComponents.day = day
        dateComponents.month = month
        dateComponents.year = year

        if let timeText {
            let timeParts = timeText.split(separator: ":").map(String.init)
            dateComponents.hour = timeParts.indices.contains(0) ? Int(timeParts[0]) : nil
            dateComponents.minute = timeParts.indices.contains(1) ? Int(timeParts[1]) : nil
            dateComponents.second = timeParts.indices.contains(2) ? Int(timeParts[2]) ?? 0 : 0
        } else {
            dateComponents.hour = 0
            dateComponents.minute = 0
            dateComponents.second = 0
        }

        return dateComponents.date
    }

    private func normalizeYear(_ rawYear: Int) -> Int {
        if rawYear >= 2500 {
            return rawYear - 543
        }

        if rawYear < 100 {
            return 2000 + rawYear
        }

        return rawYear
    }

    private func firstMatch(for pattern: String, in text: String, group: Int) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let matchRange = Range(match.range(at: group), in: text) else {
            return nil
        }

        return String(text[matchRange])
    }

    private struct BankDefinition {
        let canonicalName: String
        let aliases: [String]
    }

    private static let receiverLabels = [
        "to", "receiver", "payee", "ชื่อผู้รับ", "ผู้รับ", "ปลายทาง", "ไปยัง"
    ]

    private static let senderLabels = [
        "from", "sender", "payer", "ผู้โอน", "ผู้ส่ง", "ต้นทาง", "จาก"
    ]

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

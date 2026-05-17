import Foundation

final class BasicSlipParserService {
    private let slipParserService = SlipParserService()
    private let candidateDetectionService = SlipCandidateDetectionService()

    func parse(
        rawText: String,
        recognizedLines: [String],
        confidence: Double,
        sourceImageName: String? = nil,
        originalFileName: String? = nil
    ) -> ParsedSlip {
        let lines = recognizedLines.isEmpty
            ? rawText
                .split(whereSeparator: \.isNewline)
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            : recognizedLines

        var parsed = slipParserService.parse(textLines: lines)
        let candidate = candidateDetectionService.detectSlipCandidate(from: rawText)

        if parsed.amount == nil {
            parsed.amount = AmountParser.extractAmount(from: rawText)
        }

        if parsed.transactionTimeText == nil {
            parsed.transactionTimeText = DateParser.extractTime(from: rawText)
        }

        if parsed.transactionDate == nil {
            parsed.transactionDate = DateParser.extractDate(from: rawText, timeText: parsed.transactionTimeText)
        }

        if parsed.bankName?.isEmpty != false {
            parsed.bankName = candidate.detectedBankName
        }

        if parsed.receiverName?.isEmpty != false {
            parsed.receiverName = bestNameCandidate(from: lines, labels: ["receiver", "to", "ผู้รับ", "ชื่อผู้รับ"])
        }

        if parsed.senderName?.isEmpty != false {
            parsed.senderName = bestNameCandidate(from: lines, labels: ["sender", "from", "ผู้โอน", "ชื่อผู้โอน"])
        }

        if parsed.transactionReference?.isEmpty != false {
            parsed.transactionReference = extractReference(from: rawText)
        }

        parsed.rawOCRText = rawText
        parsed.ocrConfidence = confidence
        parsed.sourceImageName = sourceImageName
        parsed.originalFileName = originalFileName
        parsed.reviewStatus = candidate.isLikelySlip ? .new : .notRecognized
        parsed.duplicateReason = nil
        parsed.status = candidate.isLikelySlip ? .needsReview : .failed

        return parsed
    }

    private func extractReference(from text: String) -> String? {
        let patterns = [
            #"(?i)(?:ref(?:erence)?|transaction id|หมายเลขอ้างอิง|เลขที่รายการ|เลขอ้างอิง|reference no\.)[^\w]{0,8}([A-Z0-9\-]{6,30})"#,
            #"(?i)(?:ref(?:erence)?|transaction id|หมายเลขอ้างอิง|เลขที่รายการ|เลขอ้างอิง|reference no\.)[^\n]*?(\d{6,30})"#
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                continue
            }

            let nsRange = NSRange(text.startIndex..., in: text)
            guard
                let match = regex.firstMatch(in: text, options: [], range: nsRange),
                match.numberOfRanges > 1,
                let range = Range(match.range(at: 1), in: text)
            else {
                continue
            }

            let reference = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !reference.isEmpty {
                return reference
            }
        }

        return nil
    }

    private func bestNameCandidate(from lines: [String], labels: [String]) -> String? {
        for (index, line) in lines.enumerated() {
            let lowercased = line.lowercased()
            guard labels.contains(where: { lowercased.contains($0.lowercased()) }) else { continue }

            if let separatorIndex = line.firstIndex(of: ":") {
                let value = line[line.index(after: separatorIndex)...].trimmingCharacters(in: .whitespacesAndNewlines)
                if isUsefulName(value) {
                    return value
                }
            }

            if lines.indices.contains(index + 1) {
                let nextValue = lines[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                if isUsefulName(nextValue) {
                    return nextValue
                }
            }
        }

        return nil
    }

    private func isUsefulName(_ value: String) -> Bool {
        value.count >= 3 && !value.containsDigit
    }
}

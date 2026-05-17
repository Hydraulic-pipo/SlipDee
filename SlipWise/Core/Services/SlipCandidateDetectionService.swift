import Foundation

struct SlipCandidateResult {
    let isLikelySlip: Bool
    let detectedBankName: String?
    let confidence: Double
    let reason: String?
}

final class SlipCandidateDetectionService {
    private struct BankDefinition {
        let canonicalName: String
        let aliases: [String]
    }

    private let slipKeywords = [
        "โอนเงิน", "โอนเงินสำเร็จ", "รายการสำเร็จ", "สำเร็จ", "จำนวนเงิน", "วันที่",
        "เวลา", "เลขที่รายการ", "ref", "reference", "promptpay", "พร้อมเพย์",
        "kbank", "scb", "ธนาคาร", "bangkok bank", "krungthai", "krungsri",
        "ttb", "gsb", "truemoney"
    ]

    private let banks: [BankDefinition] = [
        BankDefinition(canonicalName: "KBank", aliases: ["กสิกรไทย", "kbank", "kasikorn"]),
        BankDefinition(canonicalName: "SCB", aliases: ["ไทยพาณิชย์", "scb"]),
        BankDefinition(canonicalName: "Bangkok Bank", aliases: ["กรุงเทพ", "bangkok bank", "bualuang"]),
        BankDefinition(canonicalName: "Krungthai", aliases: ["กรุงไทย", "krungthai"]),
        BankDefinition(canonicalName: "Krungsri", aliases: ["กรุงศรี", "krungsri"]),
        BankDefinition(canonicalName: "TTB", aliases: ["ทีทีบี", "ttb"]),
        BankDefinition(canonicalName: "GSB", aliases: ["ออมสิน", "gsb"]),
        BankDefinition(canonicalName: "TrueMoney Wallet", aliases: ["truemoney", "true money"])
    ]

    func detectSlipCandidate(from rawText: String) -> SlipCandidateResult {
        let normalized = rawText.lowercased()
        let keywordHits = slipKeywords.filter { normalized.contains($0.lowercased()) }
        let detectedBank = banks.first { bank in
            bank.aliases.contains { normalized.contains($0.lowercased()) }
        }?.canonicalName

        let hasAmount = AmountParser.extractAmount(from: rawText) != nil
        let hasDate = DateParser.extractDate(from: rawText, timeText: DateParser.extractTime(from: rawText)) != nil
        let score = min(
            1.0,
            Double(keywordHits.count) * 0.18
                + (detectedBank == nil ? 0 : 0.24)
                + (hasAmount ? 0.22 : 0)
                + (hasDate ? 0.14 : 0)
        )
        let isLikelySlip = keywordHits.count >= 2 || (detectedBank != nil && hasAmount)

        return SlipCandidateResult(
            isLikelySlip: isLikelySlip,
            detectedBankName: detectedBank,
            confidence: score,
            reason: isLikelySlip ? nil : "Slip-like keywords were too weak for a confident match."
        )
    }
}

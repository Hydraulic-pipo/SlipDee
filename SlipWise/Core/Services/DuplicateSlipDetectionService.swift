import Foundation

struct DuplicateCheckResult {
    let isDuplicate: Bool
    let reason: String?
    let matchedTransactionID: UUID?
}

final class DuplicateSlipDetectionService {
    func checkDuplicate(
        parsedSlip: ParsedSlip,
        existingTransactions: [TransactionItem]
    ) -> DuplicateCheckResult {
        let reference = parsedSlip.transactionReference?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !reference.isEmpty,
           let strongMatch = existingTransactions.first(where: { $0.transactionReference.caseInsensitiveCompare(reference) == .orderedSame }) {
            return DuplicateCheckResult(
                isDuplicate: true,
                reason: "Reference number matches an existing transaction.",
                matchedTransactionID: strongMatch.id
            )
        }

        guard
            let parsedAmount = parsedSlip.amount,
            let parsedDate = parsedSlip.transactionDate
        else {
            return DuplicateCheckResult(isDuplicate: false, reason: nil, matchedTransactionID: nil)
        }

        let possibleMatch = existingTransactions.first { transaction in
            abs(transaction.amount - parsedAmount) < 0.01
                && Calendar.current.isDate(transaction.transactionDate, inSameDayAs: parsedDate)
                && namesOrBanksMatch(transaction: transaction, parsedSlip: parsedSlip)
        }

        if let possibleMatch {
            return DuplicateCheckResult(
                isDuplicate: true,
                reason: "Amount and date match a saved transaction, with a similar bank or receiver.",
                matchedTransactionID: possibleMatch.id
            )
        }

        return DuplicateCheckResult(isDuplicate: false, reason: nil, matchedTransactionID: nil)
    }

    private func namesOrBanksMatch(transaction: TransactionItem, parsedSlip: ParsedSlip) -> Bool {
        let receiver = parsedSlip.receiverName?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        let bank = parsedSlip.bankName?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""

        let transactionReceiver = transaction.receiverName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let transactionMerchant = transaction.merchantName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let transactionBank = transaction.bankName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let receiverMatches = !receiver.isEmpty && (transactionReceiver.contains(receiver) || transactionMerchant.contains(receiver) || receiver.contains(transactionReceiver))
        let bankMatches = !bank.isEmpty && (!transactionBank.isEmpty && (transactionBank.contains(bank) || bank.contains(transactionBank)))

        return receiverMatches || bankMatches
    }
}

import Foundation

final class CSVExportService {
    private let csvDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    func makeCSV(
        transactions: [TransactionItem],
        categories: [TransactionCategory]
    ) throws -> String {
        let categoryLookup = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.name) })
        let headers = [
            "id",
            "date",
            "type",
            "amount",
            "currency",
            "category",
            "payment_method",
            "merchant_name",
            "receiver_name",
            "sender_name",
            "bank_name",
            "reference_number",
            "note",
            "is_from_slip",
            "is_duplicate_suspected",
            "created_at",
            "updated_at"
        ]

        let rows = transactions.map { transaction in
            [
                transaction.id.uuidString,
                csvDateFormatter.string(from: transaction.transactionDate),
                transaction.typeRawValue,
                numericAmountString(transaction.amount),
                transaction.currencyCode,
                resolveCategoryName(for: transaction, categories: categoryLookup),
                transaction.paymentMethodRawValue,
                transaction.merchantName,
                transaction.receiverName,
                transaction.senderName,
                transaction.bankName,
                transaction.transactionReference,
                transaction.note,
                transaction.isFromSlip ? "true" : "false",
                transaction.isDuplicateSuspected ? "true" : "false",
                csvDateFormatter.string(from: transaction.createdAt),
                csvDateFormatter.string(from: transaction.updatedAt)
            ]
        }

        let csvLines = ([headers] + rows).map { row in
            row.map(escapeCSVField).joined(separator: ",")
        }

        return csvLines.joined(separator: "\n")
    }

    func writeCSVToTemporaryFile(
        csvString: String,
        fileName: String
    ) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try csvString.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func resolveCategoryName(
        for transaction: TransactionItem,
        categories: [UUID: String]
    ) -> String {
        guard let categoryID = transaction.categoryID else {
            return "Uncategorized"
        }

        return categories[categoryID] ?? "Uncategorized"
    }

    private func numericAmountString(_ amount: Double) -> String {
        String(format: "%.2f", amount)
    }

    private func escapeCSVField(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        let needsQuoting = escaped.contains(",") || escaped.contains("\n") || escaped.contains("\"") || escaped.contains("\r")
        return needsQuoting ? "\"\(escaped)\"" : escaped
    }
}

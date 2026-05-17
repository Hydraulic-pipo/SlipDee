import Foundation

enum ExportScope: String, CaseIterable, Identifiable {
    case all
    case currentMonth
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All Transactions"
        case .currentMonth:
            return "This Month"
        case .custom:
            return "Custom Date Range"
        }
    }
}

struct ExportSummary {
    let transactionCount: Int
    let totalIncome: Double
    let totalExpense: Double
    let startDate: Date?
    let endDate: Date?
}

@MainActor
final class DataExportViewModel: ObservableObject {
    @Published var exportScope: ExportScope = .all
    @Published var customStartDate: Date
    @Published var customEndDate: Date
    @Published var errorMessage: String?
    @Published var generatedFileURL: URL?
    @Published var isExporting = false

    private let calendar: Calendar
    private let exportService: CSVExportService

    init(
        calendar: Calendar = .current,
        exportService: CSVExportService = CSVExportService()
    ) {
        self.calendar = calendar
        self.exportService = exportService

        let now = Date()
        let monthInterval = calendar.dateInterval(of: .month, for: now)
        self.customStartDate = monthInterval?.start ?? now
        self.customEndDate = monthInterval?.end.addingTimeInterval(-1) ?? now
    }

    func filteredTransactions(from transactions: [TransactionItem]) -> [TransactionItem] {
        if exportScope == .all {
            return transactions.sorted { $0.transactionDate > $1.transactionDate }
        }

        guard let dateRange = resolvedDateRange() else {
            return []
        }

        return transactions
            .filter { dateRange.contains($0.transactionDate) }
            .sorted { $0.transactionDate > $1.transactionDate }
    }

    func exportSummary(from transactions: [TransactionItem]) -> ExportSummary {
        let selectedTransactions = filteredTransactions(from: transactions)
        let totalIncome = selectedTransactions
            .filter { $0.typeRawValue == TransactionType.income.rawValue }
            .reduce(0) { $0 + $1.amount }
        let totalExpense = selectedTransactions
            .filter { $0.typeRawValue == TransactionType.expense.rawValue }
            .reduce(0) { $0 + $1.amount }

        return ExportSummary(
            transactionCount: selectedTransactions.count,
            totalIncome: totalIncome,
            totalExpense: totalExpense,
            startDate: summaryStartDate(from: selectedTransactions),
            endDate: summaryEndDate(from: selectedTransactions)
        )
    }

    func validateDateRange() -> Bool {
        guard exportScope == .custom else {
            errorMessage = nil
            return true
        }

        guard customStartDate <= customEndDate else {
            errorMessage = "Please choose a valid date range."
            return false
        }

        errorMessage = nil
        return true
    }

    func clearShareFile() {
        generatedFileURL = nil
    }

    func generateCSV(
        transactions: [TransactionItem],
        categories: [TransactionCategory]
    ) async {
        guard validateDateRange() else { return }

        let selectedTransactions = filteredTransactions(from: transactions)
        guard !selectedTransactions.isEmpty else {
            errorMessage = "No transactions to export."
            return
        }

        isExporting = true
        errorMessage = nil

        do {
            let csvString = try exportService.makeCSV(
                transactions: selectedTransactions,
                categories: categories
            )
            let url = try exportService.writeCSVToTemporaryFile(
                csvString: csvString,
                fileName: exportFileName()
            )
            generatedFileURL = url
        } catch {
            errorMessage = "Could not create the CSV file right now. Please try again."
        }

        isExporting = false
    }

    func exportFileName() -> String {
        switch exportScope {
        case .all:
            return "SlipDee_Transactions_All_\(fileDayString(from: Date())).csv"
        case .currentMonth:
            let monthDate = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
            return "SlipDee_Transactions_\(fileMonthString(from: monthDate)).csv"
        case .custom:
            return "SlipDee_Transactions_\(fileDayString(from: customStartDate))_to_\(fileDayString(from: customEndDate)).csv"
        }
    }

    private func resolvedDateRange() -> ClosedRange<Date>? {
        switch exportScope {
        case .all:
            return nil
        case .currentMonth:
            guard let monthInterval = calendar.dateInterval(of: .month, for: Date()) else {
                return nil
            }
            return monthInterval.start...monthInterval.end.addingTimeInterval(-1)
        case .custom:
            guard customStartDate <= customEndDate else {
                return nil
            }
            let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: customEndDate) ?? customEndDate
            return customStartDate...endOfDay
        }
    }

    private func summaryStartDate(from transactions: [TransactionItem]) -> Date? {
        switch exportScope {
        case .all:
            return transactions.last?.transactionDate
        case .currentMonth:
            return resolvedDateRange()?.lowerBound
        case .custom:
            return customStartDate
        }
    }

    private func summaryEndDate(from transactions: [TransactionItem]) -> Date? {
        switch exportScope {
        case .all:
            return transactions.first?.transactionDate
        case .currentMonth:
            return resolvedDateRange()?.upperBound
        case .custom:
            return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: customEndDate) ?? customEndDate
        }
    }

    private func fileDayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func fileMonthString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }
}

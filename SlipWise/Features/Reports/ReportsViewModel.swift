import Foundation

enum ReportRange: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    case custom = "Custom"

    var id: String { rawValue }
}

struct ReportTrendPoint: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let total: Double
}

enum ReportsViewModel {
    static func filteredTransactions(
        from transactions: [TransactionItem],
        range: ReportRange,
        anchorDate: Date,
        calendar: Calendar = .current
    ) -> [TransactionItem] {
        transactions.filter { item in
            switch range {
            case .week:
                return calendar.isDate(item.transactionDate, equalTo: anchorDate, toGranularity: .weekOfYear)
            case .month, .custom:
                return calendar.isDate(item.transactionDate, equalTo: anchorDate, toGranularity: .month)
            case .year:
                return calendar.isDate(item.transactionDate, equalTo: anchorDate, toGranularity: .year)
            }
        }
    }

    static func expenseTransactions(
        from transactions: [TransactionItem],
        range: ReportRange,
        anchorDate: Date,
        calendar: Calendar = .current
    ) -> [TransactionItem] {
        filteredTransactions(from: transactions, range: range, anchorDate: anchorDate, calendar: calendar)
            .filter { $0.type == .expense }
    }

    static func totalSpent(for transactions: [TransactionItem]) -> Double {
        transactions.reduce(0) { $0 + abs($1.amount) }
    }

    static func comparisonTotal(
        from transactions: [TransactionItem],
        range: ReportRange,
        anchorDate: Date,
        calendar: Calendar = .current
    ) -> Double {
        guard let comparisonDate = comparisonDate(for: range, anchorDate: anchorDate, calendar: calendar) else {
            return 0
        }

        return totalSpent(
            for: expenseTransactions(
                from: transactions,
                range: range,
                anchorDate: comparisonDate,
                calendar: calendar
            )
        )
    }

    static func comparisonText(
        currentTotal: Double,
        previousTotal: Double,
        range: ReportRange,
        anchorDate: Date,
        calendar: Calendar = .current
    ) -> String {
        guard previousTotal > 0 else {
            return "New period, fresh start"
        }

        let change = ((currentTotal - previousTotal) / previousTotal) * 100
        let symbol = change <= 0 ? "↓" : "↑"
        return "\(symbol) \(abs(change).formatted(.number.precision(.fractionLength(0))))% vs \(comparisonLabel(for: range, anchorDate: anchorDate, calendar: calendar))"
    }

    static func trendPoints(
        from transactions: [TransactionItem],
        range: ReportRange,
        calendar: Calendar = .current
    ) -> [ReportTrendPoint] {
        let grouped = Dictionary(grouping: transactions) { transaction in
            calendar.startOfDay(for: transaction.transactionDate)
        }

        let points = grouped
            .map { date, values in
                ReportTrendPoint(date: date, total: values.reduce(0) { $0 + abs($1.amount) })
            }
            .sorted { $0.date < $1.date }

        switch range {
        case .week:
            return Array(points.suffix(7))
        case .month, .custom:
            return points
        case .year:
            return points
        }
    }

    static func categorySummary(
        from transactions: [TransactionItem],
        categories: [TransactionCategory]
    ) -> CategorySpendingSummary {
        CategorySpendingSummaryBuilder.build(from: transactions, categories: categories)
    }

    private static func comparisonDate(
        for range: ReportRange,
        anchorDate: Date,
        calendar: Calendar
    ) -> Date? {
        switch range {
        case .week:
            return calendar.date(byAdding: .weekOfYear, value: -1, to: anchorDate)
        case .month, .custom:
            return calendar.date(byAdding: .month, value: -1, to: anchorDate)
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: anchorDate)
        }
    }

    private static func comparisonLabel(
        for range: ReportRange,
        anchorDate: Date,
        calendar: Calendar
    ) -> String {
        guard let comparisonDate = comparisonDate(for: range, anchorDate: anchorDate, calendar: calendar) else {
            return "last period"
        }

        switch range {
        case .week:
            return reportComparisonWeekFormatter.string(from: comparisonDate)
        case .month, .custom:
            return reportComparisonMonthFormatter.string(from: comparisonDate)
        case .year:
            return reportComparisonYearFormatter.string(from: comparisonDate)
        }
    }

    private static let reportComparisonMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()

    private static let reportComparisonWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()

    private static let reportComparisonYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()
}

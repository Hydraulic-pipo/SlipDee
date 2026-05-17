import Charts
import SwiftData
import SwiftUI

struct ReportsView: View {
    @AppStorage(AppSettingsKey.isHideAmountsEnabled) private var isHideAmountsEnabled = false
    @State private var selectedRange: ReportRange = .month
    @State private var selectedDate: Date = .now
    @Query(sort: \TransactionCategory.sortOrder)
    private var categories: [TransactionCategory]
    @Query(sort: \TransactionItem.transactionDate, order: .reverse)
    private var transactions: [TransactionItem]

    private var filteredTransactions: [TransactionItem] {
        ReportsViewModel.filteredTransactions(from: transactions, range: selectedRange, anchorDate: selectedDate)
    }

    private var expenseTransactions: [TransactionItem] {
        ReportsViewModel.expenseTransactions(from: transactions, range: selectedRange, anchorDate: selectedDate)
    }

    private var totalSpent: Double {
        ReportsViewModel.totalSpent(for: expenseTransactions)
    }

    private var comparisonSpent: Double {
        ReportsViewModel.comparisonTotal(from: transactions, range: selectedRange, anchorDate: selectedDate)
    }

    private var spendingChangeText: String {
        ReportsViewModel.comparisonText(
            currentTotal: totalSpent,
            previousTotal: comparisonSpent,
            range: selectedRange,
            anchorDate: selectedDate
        )
    }

    private var categorySummary: CategorySpendingSummary {
        ReportsViewModel.categorySummary(from: expenseTransactions, categories: categories)
    }

    private var spendingInsightText: String {
        SpendingInsightProvider.insight(
            currentMonthExpense: totalSpent,
            previousMonthExpense: comparisonSpent,
            topCategoryName: categorySummary.items.first?.categoryName
        )
    }

    private var chartPoints: [ReportTrendPoint] {
        ReportsViewModel.trendPoints(from: expenseTransactions, range: selectedRange)
    }

    var body: some View {
        AppScreen {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    Text("Reports")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)

                    Picker("Range", selection: $selectedRange) {
                        ForEach(ReportRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)

                    periodSelector

                    summaryCard
                    chartCard
                    categorySection
                    insightCard
                }
                .padding(.horizontal, AppSpacing.page)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summaryCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Total Spent")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.secondaryText)

                Text(AmountDisplayFormatter.display(amount: totalSpent, isHidden: isHideAmountsEnabled))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryText)

                Text(spendingChangeText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(totalSpent <= comparisonSpent ? AppColors.income : AppColors.expense)
            }
        }
    }

    private var chartCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Spending Trend")
                    .font(.headline)
                    .foregroundStyle(AppColors.primaryText)

                if chartPoints.isEmpty {
                    Text("No expense data yet for this period.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)
                } else {
                    Chart(chartPoints) { item in
                        BarMark(
                            x: .value("Day", DateFormatter.reportDay.string(from: item.date)),
                            y: .value("Amount", item.total)
                        )
                        .foregroundStyle(AppColors.expense)
                        .cornerRadius(6)
                    }
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .foregroundStyle(AppColors.secondaryText)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine()
                                .foregroundStyle(AppColors.border)
                            AxisValueLabel()
                                .foregroundStyle(AppColors.secondaryText)
                        }
                    }
                    .frame(height: 230)
                }
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            AppSectionHeader("Spending by Category", subtitle: "Expense categories for the selected period.")

            if categorySummary.isEmpty {
                EmptyStateCard(
                    icon: "chart.pie",
                    title: "No expenses yet",
                    message: "Add a transaction or scan a slip to see your category chart."
                )
            } else {
                CategoryDonutChartView(summary: categorySummary, isHideAmountsEnabled: isHideAmountsEnabled)
                CategoryBreakdownListView(items: categorySummary.items, isHideAmountsEnabled: isHideAmountsEnabled)
            }
        }
    }

    private var insightCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Spending Insight")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.darkTeal)

                Text(spendingInsightText)
                    .font(.headline)
                    .foregroundStyle(AppColors.primaryText)
            }
            .padding(4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.softMint)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous))
        }
        .background(Color.clear)
    }

    private var periodSelector: some View {
        HStack {
            Button {
                shiftPeriod(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)
                    .frame(width: 36, height: 36)
                    .background(AppColors.cardBackground)
                    .overlay(
                        Circle()
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            }

            Spacer()

            Text(periodTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.secondaryText)

            Spacer()

            Button {
                shiftPeriod(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)
                    .frame(width: 36, height: 36)
                    .background(AppColors.cardBackground)
                    .overlay(
                        Circle()
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            }
        }
    }

    private var periodTitle: String {
        switch selectedRange {
        case .week:
            return DateFormatter.reportComparisonWeek.string(from: selectedDate)
        case .month, .custom:
            return DateFormatter.reportMonth.string(from: selectedDate)
        case .year:
            return DateFormatter.reportComparisonYear.string(from: selectedDate)
        }
    }

    private func shiftPeriod(by value: Int) {
        let calendar = Calendar.current

        switch selectedRange {
        case .week:
            selectedDate = calendar.date(byAdding: .weekOfYear, value: value, to: selectedDate) ?? selectedDate
        case .month, .custom:
            selectedDate = calendar.date(byAdding: .month, value: value, to: selectedDate) ?? selectedDate
        case .year:
            selectedDate = calendar.date(byAdding: .year, value: value, to: selectedDate) ?? selectedDate
        }
    }
}

private extension DateFormatter {
    static let reportMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    static let reportComparisonMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()

    static let reportComparisonWeek: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()

    static let reportComparisonYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()

    static let reportDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }()
}

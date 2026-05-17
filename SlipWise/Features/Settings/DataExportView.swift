import SwiftData
import SwiftUI

struct DataExportView: View {
    @Query(sort: \TransactionItem.transactionDate, order: .reverse)
    private var transactions: [TransactionItem]

    @Query(sort: \TransactionCategory.sortOrder)
    private var categories: [TransactionCategory]

    @StateObject private var viewModel = DataExportViewModel()

    private var selectedTransactions: [TransactionItem] {
        viewModel.filteredTransactions(from: transactions)
    }

    private var summary: ExportSummary {
        viewModel.exportSummary(from: transactions)
    }

    private var hasTransactionsToExport: Bool {
        !selectedTransactions.isEmpty
    }

    var body: some View {
        AppScreen {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    headerSection
                    exportOptionsSection
                    exportSummarySection
                    privacySection
                    comingSoonSection
                }
                .padding(.horizontal, AppSpacing.page)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Data & Export")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: Binding(
            get: { viewModel.generatedFileURL != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearShareFile()
                }
            }
        )) {
            if let url = viewModel.generatedFileURL {
                ShareSheetView(items: [url])
            }
        }
    }

    private var headerSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Export your data", systemImage: "square.and.arrow.up")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppColors.primaryText)

                Text("Download your transaction history as a CSV file. You can open it in Excel, Numbers, or Google Sheets.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)

                Text("Your data is exported locally on this device.")
                    .font(.caption)
                    .foregroundStyle(AppColors.mutedText)
            }
        }
    }

    private var exportOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Options")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.secondaryText)

            AppCard {
                VStack(alignment: .leading, spacing: 14) {
                    Picker("Export Scope", selection: $viewModel.exportScope) {
                        ForEach(ExportScope.allCases) { scope in
                            Text(scope.title).tag(scope)
                        }
                    }
                    .pickerStyle(.segmented)

                    if viewModel.exportScope == .custom {
                        VStack(alignment: .leading, spacing: 12) {
                            datePickerRow(title: "Start Date", selection: $viewModel.customStartDate)
                            datePickerRow(title: "End Date", selection: $viewModel.customEndDate)
                        }
                        .padding(14)
                        .background(AppColors.elevatedCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous))
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.expense)
                    }

                    Button {
                        Task {
                            await viewModel.generateCSV(
                                transactions: transactions,
                                categories: categories
                            )
                        }
                    } label: {
                        HStack {
                            if viewModel.isExporting {
                                ProgressView()
                                    .tint(.white)
                            }

                            Text(viewModel.isExporting ? "Preparing CSV..." : "Export CSV")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(.white)
                        .background(hasTransactionsToExport ? AppColors.primaryTeal : AppColors.mutedText)
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!hasTransactionsToExport || viewModel.isExporting)
                }
            }
        }
    }

    private var exportSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Summary")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.secondaryText)

            AppCard {
                if hasTransactionsToExport {
                    VStack(alignment: .leading, spacing: 14) {
                        summaryRow(title: "Transactions", value: "\(summary.transactionCount)")
                        summaryRow(title: "Total Income", value: CurrencyFormatter.bahtString(from: summary.totalIncome))
                        summaryRow(title: "Total Expense", value: CurrencyFormatter.bahtString(from: summary.totalExpense))
                        summaryRow(title: "Date Range", value: summaryDateRangeText)
                        summaryRow(title: "File Format", value: "CSV")
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No transactions to export")
                            .font(.headline)
                            .foregroundStyle(AppColors.primaryText)

                        Text("Add a transaction or scan a slip before exporting your data.")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                }
            }
        }
    }

    private var privacySection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Privacy")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)

                Text("CSV files may contain financial details. Share them only with people you trust.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)

                Text("SlipDee creates this file locally on your device.")
                    .font(.caption)
                    .foregroundStyle(AppColors.mutedText)
            }
        }
    }

    private var comingSoonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coming Soon")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.secondaryText)

            AppCard {
                VStack(spacing: 0) {
                    disabledRow(icon: "doc.richtext", title: "PDF Monthly Report")
                    divider
                    disabledRow(icon: "tablecells", title: "Excel Export")
                    divider
                    disabledRow(icon: "icloud", title: "iCloud Backup")
                    divider
                    disabledRow(icon: "arrow.clockwise.doc", title: "Restore from Backup")
                }
            }
        }
    }

    private func datePickerRow(title: String, selection: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.secondaryText)

            DatePicker(
                "",
                selection: selection,
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .tint(AppColors.primaryTeal)
        }
    }

    private func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppColors.secondaryText)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.primaryText)
                .multilineTextAlignment(.trailing)
        }
    }

    private func disabledRow(icon: String, title: String) -> some View {
        SettingsRowView(
            icon: icon,
            title: title,
            trailingText: "Coming Soon",
            showsChevron: false
        )
        .padding(.vertical, 10)
        .opacity(0.72)
    }

    private var summaryDateRangeText: String {
        guard let startDate = summary.startDate, let endDate = summary.endDate else {
            return "All available dates"
        }

        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    private var divider: some View {
        Divider()
            .overlay(AppColors.border)
            .padding(.leading, 48)
    }
}

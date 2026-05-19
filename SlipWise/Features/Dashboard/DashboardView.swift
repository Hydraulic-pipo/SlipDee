import SwiftData
import SwiftUI

struct DashboardView: View {
    @AppStorage(AppSettingsKey.userDisplayName) private var userDisplayName = ""
    @AppStorage(AppSettingsKey.isHideAmountsEnabled) private var isHideAmountsEnabled = false
    @State private var showingManualTransactionForm = false
    @State private var showingSlipImport = false
    @State private var showingMultipleSlipScan = false
    @State private var showingMonthPicker = false
    @State private var greetingText = GreetingProvider.greeting(displayName: nil)
    @State private var selectedMonth: Int
    @State private var selectedYear: Int

    @Query(sort: \TransactionItem.transactionDate, order: .reverse)
    private var transactions: [TransactionItem]

    init() {
        let now = Date()
        let calendar = Calendar.current
        _selectedMonth = State(initialValue: calendar.component(.month, from: now))
        _selectedYear = State(initialValue: calendar.component(.year, from: now))
    }

    private var selectedMonthTransactions: [TransactionItem] {
        transactions.filter {
            let components = Calendar.current.dateComponents([.month, .year], from: $0.transactionDate)
            return components.month == selectedMonth && components.year == selectedYear
        }
    }

    private var incomeTotal: Double {
        selectedMonthTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }

    private var expenseTotal: Double {
        selectedMonthTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    private var balanceTotal: Double {
        incomeTotal - expenseTotal
    }

    private var recentTransactions: [TransactionItem] {
        Array(selectedMonthTransactions.sorted { $0.transactionDate > $1.transactionDate }.prefix(4))
    }

    private var monthTitle: String {
        MonthYearFormatter.displayName(month: selectedMonth, year: selectedYear)
    }

    var body: some View {
        AppScreen {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    headerSection
                    balanceCard
                    actionButtons
                    recentSection
                }
                .padding(.horizontal, AppSpacing.page)
                .padding(.top, 16)
                .padding(.bottom, 36)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshGreeting()
        }
        .onChange(of: userDisplayName) { _, _ in
            refreshGreeting()
        }
        .sheet(isPresented: $showingManualTransactionForm) {
            ManualTransactionFormView()
        }
        .sheet(isPresented: $showingSlipImport) {
            NavigationStack {
                ScanSlipView(onSaveComplete: {
                    showingSlipImport = false
                })
            }
        }
        .sheet(isPresented: $showingMultipleSlipScan) {
            NavigationStack {
                MultipleSlipScanView()
            }
        }
        .sheet(isPresented: $showingMonthPicker) {
            MonthPickerSheet(
                selectedMonth: $selectedMonth,
                selectedYear: $selectedYear
            )
        }
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 14) {
                Text(greetingText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryText)

                Button {
                    showingMonthPicker = true
                } label: {
                    HStack(spacing: 8) {
                        Text(monthTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppColors.primaryText)

                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppColors.cardBackground)
                    .overlay(
                        Capsule()
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Image(systemName: "bell")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 40, height: 40)
                .background(AppColors.cardBackground)
                .overlay(
                    Circle()
                        .stroke(AppColors.border, lineWidth: 1)
                )
                .clipShape(Circle())
        }
    }

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Total Balance")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.84))

            Text(AmountDisplayFormatter.display(amount: balanceTotal, isHidden: isHideAmountsEnabled))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Income \(AmountDisplayFormatter.display(amount: incomeTotal, isHidden: isHideAmountsEnabled))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(monthTitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.78))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text("Spent \(AmountDisplayFormatter.display(amount: expenseTotal, isHidden: isHideAmountsEnabled))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(monthTitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.78))
                }
            }
        }
        .padding(22)
        .background(AppColors.primaryTeal)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
        .shadow(color: AppColors.primaryTeal.opacity(0.18), radius: 18, x: 0, y: 10)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                actionCard(
                    title: "Scan Slip",
                    subtitle: "Import one slip",
                    icon: "doc.viewfinder"
                ) {
                    showingSlipImport = true
                }
                .frame(maxWidth: .infinity)

                actionCard(
                    title: "Add Manually",
                    subtitle: "Income or expense",
                    icon: "square.and.pencil"
                ) {
                    showingManualTransactionForm = true
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)

            Button {
                showingMultipleSlipScan = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Scan Today’s Slips")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.primaryTeal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous)
                        .stroke(AppColors.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.card) {
            AppSectionHeader("Recent Transactions", trailing: recentTransactions.isEmpty ? nil : "View all")

            if recentTransactions.isEmpty {
                EmptyStateCard(
                    icon: "tray",
                    title: "No transactions for this month",
                    message: "Add a transaction or scan a slip to start tracking this month."
                )
            } else {
                ForEach(recentTransactions) { transaction in
                    TransactionRowView(transaction: transaction)
                }
            }
        }
    }

    private func actionCard(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            AppCard {
                VStack(alignment: .leading, spacing: 14) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.primaryTeal)
                        .frame(width: 42, height: 42)
                        .background(AppColors.softMint)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppColors.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                }
                .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    private func refreshGreeting() {
        greetingText = GreetingProvider.greeting(displayName: userDisplayName)
    }
}

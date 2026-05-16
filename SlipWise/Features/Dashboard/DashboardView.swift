import SwiftData
import SwiftUI

struct DashboardView: View {
    @State private var showingManualTransactionForm = false
    @State private var showingSlipImport = false
    @State private var greetingText = GreetingProvider.greeting()

    @Query(sort: \TransactionItem.transactionDate, order: .reverse)
    private var transactions: [TransactionItem]

    private var thisMonthTransactions: [TransactionItem] {
        let now = Date()
        return transactions.filter { Calendar.current.isDate($0.transactionDate, equalTo: now, toGranularity: .month) }
    }

    private var incomeTotal: Double {
        thisMonthTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }

    private var expenseTotal: Double {
        thisMonthTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    private var balanceTotal: Double {
        incomeTotal - expenseTotal
    }

    private var recentTransactions: [TransactionItem] {
        Array(transactions.prefix(4))
    }

    private var monthTitle: String {
        DateFormatter.dashboardMonth.string(from: .now)
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
            greetingText = GreetingProvider.greeting()
        }
        .sheet(isPresented: $showingManualTransactionForm) {
            ManualTransactionFormView()
        }
        .sheet(isPresented: $showingSlipImport) {
            NavigationStack {
                ScanSlipView()
            }
        }
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 14) {
                Text(greetingText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryText)

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

            Text(CurrencyFormatter.bahtString(from: balanceTotal))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Income \(CurrencyFormatter.bahtString(from: incomeTotal))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("This month")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.78))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text("Spent \(CurrencyFormatter.bahtString(from: expenseTotal))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("This month")
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
        HStack(spacing: 14) {
            actionCard(
                title: "Scan Slip",
                subtitle: "Import bank slip",
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
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.card) {
            AppSectionHeader("Recent Transactions", trailing: recentTransactions.isEmpty ? nil : "View all")

            if recentTransactions.isEmpty {
                EmptyStateCard(
                    icon: "tray",
                    title: "No transactions yet",
                    message: "Add a manual entry or import your first slip to see activity here."
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
}

private extension DateFormatter {
    static let dashboardMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
}

import SwiftData
import SwiftUI

struct DashboardView: View {
    @AppStorage(AppSettingsKey.userDisplayName) private var userDisplayName = ""
    @AppStorage(AppSettingsKey.isHideAmountsEnabled) private var isHideAmountsEnabled = false

    @Environment(\.modelContext) private var modelContext

    @State private var showingManualTransactionForm = false
    @State private var showingSlipImport = false
    @State private var showingMultipleSlipScan = false
    @State private var showingMonthPicker = false
    @State private var greetingText = GreetingProvider.greeting(displayName: nil)
    @State private var statusMessage: String?
    @State private var recurringIncomeToSkip: RecurringIncome?
    @State private var duplicateRecurringIncomeToConfirm: RecurringIncome?
    @State private var selectedMonth: Int
    @State private var selectedYear: Int

    @Query(sort: \TransactionItem.transactionDate, order: .reverse)
    private var transactions: [TransactionItem]

    @Query(sort: \TransactionCategory.sortOrder)
    private var categories: [TransactionCategory]

    @Query(sort: \RecurringIncome.createdAt, order: .forward)
    private var recurringIncomes: [RecurringIncome]

    @Query(sort: \RecurringIncomeOccurrence.createdAt, order: .forward)
    private var recurringIncomeOccurrences: [RecurringIncomeOccurrence]

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

    private var pendingRecurringIncomes: [RecurringIncome] {
        recurringIncomes
            .filter { $0.isActive }
            .filter { occurrence(for: $0)?.status != .confirmed && occurrence(for: $0)?.status != .skipped }
            .sorted { lhs, rhs in
                if lhs.payDay == rhs.payDay {
                    return lhs.createdAt < rhs.createdAt
                }
                return lhs.payDay < rhs.payDay
            }
    }

    var body: some View {
        AppScreen {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    headerSection
                    balanceCard

                    if let statusMessage {
                        statusCard(message: statusMessage)
                    }

                    if !pendingRecurringIncomes.isEmpty {
                        expectedIncomeSection
                    }

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
        .alert("Skip this income?", isPresented: skipAlertBinding, presenting: recurringIncomeToSkip) { recurringIncome in
            Button("Cancel", role: .cancel) {
                recurringIncomeToSkip = nil
            }
            Button("Skip", role: .destructive) {
                skipRecurringIncome(recurringIncome)
            }
        } message: { _ in
            Text("This will hide it for this month without creating a transaction.")
        }
        .alert("This income may already be recorded.", isPresented: duplicateAlertBinding, presenting: duplicateRecurringIncomeToConfirm) { recurringIncome in
            Button("Cancel", role: .cancel) {
                duplicateRecurringIncomeToConfirm = nil
            }
            Button("Confirm Anyway") {
                confirmRecurringIncome(recurringIncome)
            }
        } message: { recurringIncome in
            Text("SlipDee found a similar income for \(recurringIncome.name) in this month. Do you want to confirm it again?")
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

    private var expectedIncomeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.card) {
            AppSectionHeader("Expected Income", subtitle: "Confirm regular income for \(monthTitle)")

            ForEach(Array(pendingRecurringIncomes.prefix(2))) { recurringIncome in
                expectedIncomeCard(for: recurringIncome)
            }

            if pendingRecurringIncomes.count > 2 {
                AppCard {
                    Text("View all expected income in Recurring Income settings.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
        }
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

    private func statusCard(message: String) -> some View {
        AppCard {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppColors.secondaryText)
        }
    }

    private func expectedIncomeCard(for recurringIncome: RecurringIncome) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(recurringIncome.name)
                            .font(.headline)
                            .foregroundStyle(AppColors.primaryText)

                        Text(
                            RecurringIncomeDateHelper.expectedDateTitle(
                                payDay: recurringIncome.payDay,
                                month: selectedMonth,
                                year: selectedYear
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                    }

                    Spacer()

                    Text(AmountDisplayFormatter.display(amount: recurringIncome.amount, isHidden: isHideAmountsEnabled))
                        .font(.title3.bold())
                        .foregroundStyle(AppColors.primaryTeal)
                }

                HStack(spacing: 12) {
                    Button("Confirm") {
                        handleConfirmTap(for: recurringIncome)
                    }
                    .buttonStyle(PrimaryFintechButtonStyle())

                    Button("Skip") {
                        recurringIncomeToSkip = recurringIncome
                    }
                    .buttonStyle(SecondaryFintechButtonStyle())
                }
            }
        }
    }

    private var skipAlertBinding: Binding<Bool> {
        Binding(
            get: { recurringIncomeToSkip != nil },
            set: { isPresented in
                if !isPresented {
                    recurringIncomeToSkip = nil
                }
            }
        )
    }

    private var duplicateAlertBinding: Binding<Bool> {
        Binding(
            get: { duplicateRecurringIncomeToConfirm != nil },
            set: { isPresented in
                if !isPresented {
                    duplicateRecurringIncomeToConfirm = nil
                }
            }
        )
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

    private func occurrence(for recurringIncome: RecurringIncome) -> RecurringIncomeOccurrence? {
        recurringIncomeOccurrences.first {
            $0.recurringIncomeID == recurringIncome.id &&
            $0.month == selectedMonth &&
            $0.year == selectedYear
        }
    }

    private func handleConfirmTap(for recurringIncome: RecurringIncome) {
        if hasPossibleDuplicate(for: recurringIncome) {
            duplicateRecurringIncomeToConfirm = recurringIncome
        } else {
            confirmRecurringIncome(recurringIncome)
        }
    }

    private func hasPossibleDuplicate(for recurringIncome: RecurringIncome) -> Bool {
        selectedMonthTransactions.contains { transaction in
            guard transaction.type == .income else { return false }
            guard abs(transaction.amount - recurringIncome.amount) < 0.01 else { return false }

            let recurringName = recurringIncome.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let receiverName = transaction.receiverName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let merchantName = transaction.merchantName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            if recurringName.isEmpty {
                return true
            }

            return recurringName == receiverName || recurringName == merchantName
        }
    }

    private func confirmRecurringIncome(_ recurringIncome: RecurringIncome) {
        duplicateRecurringIncomeToConfirm = nil

        let categoryDefinition = resolvedCategoryDefinition(for: recurringIncome.categoryID)
        let now = Date()
        let trimmedName = recurringIncome.name.trimmingCharacters(in: .whitespacesAndNewlines)

        let transaction = TransactionItem(
            categoryDefinition: categoryDefinition,
            amount: recurringIncome.amount,
            currencyCode: recurringIncome.currencyCode,
            type: .income,
            paymentMethod: recurringIncome.paymentMethod,
            merchantName: "",
            bankName: "",
            receiverName: trimmedName.isEmpty ? "Salary" : trimmedName,
            senderName: "",
            transactionReference: "",
            transactionDate: transactionDateForConfirmation(recurringIncome),
            note: recurringIncome.note ?? "",
            isFromSlip: false,
            isDuplicateSuspected: false,
            sourceImageName: nil,
            createdAt: now,
            updatedAt: now
        )

        modelContext.insert(transaction)

        let occurrence = occurrence(for: recurringIncome)
            ?? RecurringIncomeOccurrence(
                recurringIncomeID: recurringIncome.id,
                month: selectedMonth,
                year: selectedYear,
                status: .confirmed
            )

        occurrence.status = .confirmed
        occurrence.transactionID = transaction.id
        occurrence.updatedAt = now

        if occurrence.modelContext == nil {
            modelContext.insert(occurrence)
        }

        do {
            try modelContext.save()
            statusMessage = "Income confirmed"
        } catch {
            statusMessage = "We couldn't confirm this income. Please try again."
        }
    }

    private func skipRecurringIncome(_ recurringIncome: RecurringIncome) {
        recurringIncomeToSkip = nil

        let now = Date()
        let occurrence = occurrence(for: recurringIncome)
            ?? RecurringIncomeOccurrence(
                recurringIncomeID: recurringIncome.id,
                month: selectedMonth,
                year: selectedYear,
                status: .skipped
            )

        occurrence.status = .skipped
        occurrence.transactionID = nil
        occurrence.updatedAt = now

        if occurrence.modelContext == nil {
            modelContext.insert(occurrence)
        }

        do {
            try modelContext.save()
            statusMessage = "Expected income skipped for this month."
        } catch {
            statusMessage = "We couldn't skip this income. Please try again."
        }
    }

    private func resolvedCategoryDefinition(for categoryID: UUID?) -> TransactionCategoryDefinition? {
        if let builtIn = TransactionCategoryCatalog.definition(for: categoryID) {
            return builtIn
        }

        guard let categoryID,
              let category = categories.first(where: { $0.id == categoryID })
        else {
            return nil
        }

        return TransactionCategoryDefinition(
            id: category.id,
            name: category.name,
            iconSystemName: category.iconSystemName,
            colorHex: category.colorHex,
            transactionType: category.transactionType,
            sortOrder: category.sortOrder
        )
    }

    private func transactionDateForConfirmation(_ recurringIncome: RecurringIncome) -> Date {
        let currentComponents = Calendar.current.dateComponents([.month, .year], from: Date())
        let isCurrentMonth = currentComponents.month == selectedMonth && currentComponents.year == selectedYear

        if isCurrentMonth {
            return Date()
        }

        return RecurringIncomeDateHelper.expectedDate(
            payDay: recurringIncome.payDay,
            month: selectedMonth,
            year: selectedYear
        ) ?? Date()
    }
}

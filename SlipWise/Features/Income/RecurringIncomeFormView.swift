import SwiftData
import SwiftUI

private enum RecurringIncomeFormMode {
    case add
    case edit(RecurringIncome)

    var title: String {
        switch self {
        case .add:
            return "Add Recurring Income"
        case .edit:
            return "Edit Recurring Income"
        }
    }

    var saveTitle: String {
        switch self {
        case .add:
            return "Save Recurring Income"
        case .edit:
            return "Update Recurring Income"
        }
    }
}

struct RecurringIncomeFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \TransactionCategory.sortOrder)
    private var categories: [TransactionCategory]

    @State private var name: String
    @State private var amountText: String
    @State private var payDayText: String
    @State private var selectedCategoryID: UUID?
    @State private var paymentMethod: PaymentMethod
    @State private var note: String
    @State private var isActive: Bool
    @State private var validationMessage: String?

    private let mode: RecurringIncomeFormMode

    init(recurringIncome: RecurringIncome? = nil) {
        if let recurringIncome {
            self.mode = .edit(recurringIncome)
            _name = State(initialValue: recurringIncome.name)
            _amountText = State(initialValue: String(format: "%.2f", recurringIncome.amount))
            _payDayText = State(initialValue: String(recurringIncome.payDay))
            _selectedCategoryID = State(initialValue: recurringIncome.categoryID)
            _paymentMethod = State(initialValue: recurringIncome.paymentMethod)
            _note = State(initialValue: recurringIncome.note ?? "")
            _isActive = State(initialValue: recurringIncome.isActive)
        } else {
            let currentDay = Calendar.current.component(.day, from: Date())
            self.mode = .add
            _name = State(initialValue: "Salary")
            _amountText = State(initialValue: "")
            _payDayText = State(initialValue: String(min(max(currentDay, 1), 30)))
            _selectedCategoryID = State(initialValue: TransactionCategoryCatalog.definition(named: "Salary")?.id)
            _paymentMethod = State(initialValue: .bankTransfer)
            _note = State(initialValue: "Monthly salary")
            _isActive = State(initialValue: true)
        }
    }

    private var filteredCategories: [TransactionCategory] {
        let matching = categories.filter { category in
            guard let type = category.transactionType else { return true }
            return type == .income
        }

        return matching.sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.name < rhs.name
            }
            return lhs.sortOrder < rhs.sortOrder
        }
    }

    var body: some View {
        AppScreen {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    Text(mode.title)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)

                    AppCard {
                        VStack(spacing: 16) {
                            AppInputField(title: "Name", text: $name)
                            AppInputField(title: "Amount", text: $amountText, keyboardType: .decimalPad)
                            AppInputField(title: "Pay Day of Month", text: $payDayText, keyboardType: .numberPad)

                            if !filteredCategories.isEmpty {
                                AppPickerField(title: "Category", selection: categorySelection) {
                                    Text("Optional")
                                        .tag(Optional<UUID>.none)

                                    ForEach(filteredCategories) { category in
                                        Text(category.name)
                                            .tag(Optional(category.id))
                                    }
                                }
                            }

                            AppPickerField(title: "Payment Method", selection: $paymentMethod) {
                                ForEach(PaymentMethod.allCases) { method in
                                    Text(method.title)
                                        .tag(method)
                                }
                            }

                            AppInputField(title: "Note", text: $note, axis: .vertical)

                            Toggle("Active", isOn: $isActive)
                                .tint(AppColors.primaryTeal)
                                .font(.subheadline.weight(.semibold))
                        }
                    }

                    if let validationMessage {
                        AppCard {
                            Text(validationMessage)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.expense)
                        }
                    }

                    VStack(spacing: 12) {
                        Button(mode.saveTitle) {
                            saveRecurringIncome()
                        }
                        .buttonStyle(PrimaryFintechButtonStyle())

                        Button("Cancel") {
                            dismiss()
                        }
                        .buttonStyle(SecondaryFintechButtonStyle())
                    }
                }
                .padding(.horizontal, AppSpacing.page)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var categorySelection: Binding<UUID?> {
        Binding(
            get: { selectedCategoryID },
            set: { selectedCategoryID = $0 }
        )
    }

    private func saveRecurringIncome() {
        validationMessage = nil

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedAmount = amountText.replacingOccurrences(of: ",", with: "")

        guard !trimmedName.isEmpty else {
            validationMessage = "Please enter a name."
            return
        }

        guard let amount = Double(normalizedAmount), amount > 0 else {
            validationMessage = "Please enter an amount greater than 0."
            return
        }

        guard let payDay = Int(payDayText), (1...31).contains(payDay) else {
            validationMessage = "Please choose a pay day between 1 and 31."
            return
        }

        let now = Date()

        switch mode {
        case .add:
            let recurringIncome = RecurringIncome(
                name: trimmedName,
                amount: amount,
                payDay: payDay,
                categoryID: selectedCategoryID,
                paymentMethod: paymentMethod,
                note: trimmedNote.isEmpty ? nil : trimmedNote,
                isActive: isActive,
                createdAt: now,
                updatedAt: now
            )
            modelContext.insert(recurringIncome)

        case let .edit(recurringIncome):
            recurringIncome.name = trimmedName
            recurringIncome.amount = amount
            recurringIncome.payDay = payDay
            recurringIncome.categoryID = selectedCategoryID
            recurringIncome.paymentMethod = paymentMethod
            recurringIncome.note = trimmedNote.isEmpty ? nil : trimmedNote
            recurringIncome.isActive = isActive
            recurringIncome.touch(at: now)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            validationMessage = "We couldn't save this recurring income. Please try again."
        }
    }
}

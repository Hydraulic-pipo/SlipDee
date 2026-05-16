import Foundation
import SwiftData

enum TransactionFormMode {
    case add
    case edit(TransactionItem)

    var isEditing: Bool {
        if case .edit = self {
            return true
        }
        return false
    }

    var title: String {
        switch self {
        case .add:
            return "Add Transaction"
        case .edit:
            return "Edit Transaction"
        }
    }

    var saveTitle: String {
        switch self {
        case .add:
            return "Save Transaction"
        case .edit:
            return "Update Transaction"
        }
    }
}

@MainActor
final class TransactionViewModel: ObservableObject {
    @Published var transactionType: TransactionType = .expense
    @Published var amountText: String = ""
    @Published var transactionDate: Date = .now
    @Published var selectedCategoryID: UUID?
    @Published var paymentMethod: PaymentMethod = .promptPay
    @Published var counterpartyName: String = ""
    @Published var note: String = ""
    @Published var validationMessage: String?
    @Published var successMessage: String?

    @Published private(set) var availableCategories: [TransactionCategory] = []

    let mode: TransactionFormMode

    init(mode: TransactionFormMode = .add) {
        self.mode = mode

        if case let .edit(transaction) = mode {
            amountText = String(format: "%.2f", transaction.amount)
            transactionType = transaction.type
            transactionDate = transaction.transactionDate
            selectedCategoryID = transaction.categoryID
            paymentMethod = transaction.paymentMethod
            counterpartyName = transaction.displayName
            note = transaction.note
        }
    }

    var filteredCategories: [TransactionCategory] {
        let matching = availableCategories.filter { category in
            guard let categoryType = category.transactionType else { return true }
            return categoryType == transactionType
        }

        return matching.sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.name < rhs.name
            }
            return lhs.sortOrder < rhs.sortOrder
        }
    }

    var parsedAmount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: ""))
    }

    var canSave: Bool {
        parsedAmount ?? 0 > 0
    }

    var counterpartyLabel: String {
        switch transactionType {
        case .income:
            return "Source or Sender"
        case .expense:
            return "Merchant or Receiver"
        case .transfer:
            return "Receiver or Account"
        }
    }

    func loadCategories(from categories: [TransactionCategory]) {
        availableCategories = categories

        if let selectedCategoryID, !filteredCategories.contains(where: { $0.id == selectedCategoryID }) {
            self.selectedCategoryID = nil
        }
    }

    func validate() -> Bool {
        validationMessage = nil
        successMessage = nil

        guard let parsedAmount, parsedAmount > 0 else {
            validationMessage = "Please enter an amount greater than 0."
            return false
        }

        return true
    }

    func save(using modelContext: ModelContext) -> Bool {
        guard validate() else { return false }
        guard let parsedAmount else { return false }

        let trimmedName = counterpartyName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let category = filteredCategories.first(where: { $0.id == selectedCategoryID })
        let now = Date()

        switch mode {
        case .add:
            let transaction = TransactionItem(
                categoryID: category?.id,
                amount: parsedAmount,
                currencyCode: CurrencyCode.thb,
                typeRawValue: transactionType.rawValue,
                paymentMethodRawValue: paymentMethod.rawValue,
                categoryName: category?.name ?? "Other",
                categoryIconName: category?.iconSystemName ?? "square.grid.2x2.fill",
                merchantName: trimmedName,
                bankName: "",
                receiverName: trimmedName,
                senderName: transactionType == .income ? trimmedName : "",
                transactionReference: "",
                transactionDate: transactionDate,
                note: trimmedNote,
                isFromSlip: false,
                isDuplicateSuspected: false,
                sourceImageName: nil,
                createdAt: now,
                updatedAt: now
            )

            modelContext.insert(transaction)
            successMessage = "Transaction saved successfully."

        case let .edit(transaction):
            transaction.amount = parsedAmount
            transaction.type = transactionType
            transaction.transactionDate = transactionDate
            transaction.categoryID = category?.id
            transaction.categoryName = category?.name ?? "Other"
            transaction.categoryIconName = category?.iconSystemName ?? "square.grid.2x2.fill"
            transaction.paymentMethod = paymentMethod
            transaction.merchantName = trimmedName
            transaction.receiverName = trimmedName
            transaction.senderName = transactionType == .income ? trimmedName : ""
            transaction.note = trimmedNote
            transaction.touch(at: now)
            successMessage = "Transaction updated successfully."
        }

        do {
            try modelContext.save()
            if case .add = mode {
                reset()
            }
            return true
        } catch {
            validationMessage = "We couldn't save this transaction. Please try again."
            return false
        }
    }

    func reset() {
        guard case .add = mode else { return }
        transactionType = .expense
        amountText = ""
        transactionDate = .now
        selectedCategoryID = nil
        paymentMethod = .promptPay
        counterpartyName = ""
        note = ""
        validationMessage = nil
    }
}

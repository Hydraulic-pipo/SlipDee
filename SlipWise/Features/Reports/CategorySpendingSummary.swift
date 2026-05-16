import Foundation
import SwiftUI

struct CategorySpendingItem: Identifiable, Hashable {
    let id: UUID
    let categoryID: UUID?
    let categoryName: String
    let amount: Double
    let percentage: Double
    let colorHex: String
    let iconName: String
}

struct CategorySpendingSummary: Hashable {
    let items: [CategorySpendingItem]
    let totalExpense: Double

    var isEmpty: Bool {
        items.isEmpty || totalExpense <= 0
    }
}

enum CategorySpendingSummaryBuilder {
    private static let maxVisibleCategories = 6
    private static let fallbackOtherColorHex = "#94A3B8"
    private static let fallbackUncategorizedColorHex = "#CBD5E1"

    static func build(
        from transactions: [TransactionItem],
        categories: [TransactionCategory]
    ) -> CategorySpendingSummary {
        let expenseTransactions = transactions.filter { $0.type == .expense }
        let totalExpense = expenseTransactions.reduce(0) { $0 + abs($1.amount) }

        guard totalExpense > 0 else {
            return CategorySpendingSummary(items: [], totalExpense: 0)
        }

        let categoriesByID = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        let grouped = Dictionary(grouping: expenseTransactions) { $0.categoryID }

        var items = grouped.map { categoryID, values in
            let category = categoryID.flatMap { categoriesByID[$0] }
            let amount = values.reduce(0) { $0 + abs($1.amount) }
            let categoryName = resolvedCategoryName(category: category, transactions: values)
            let iconName = category?.iconSystemName ?? values.first?.categoryIconName ?? "square.grid.2x2.fill"
            let colorHex = resolvedColorHex(category: category, transactions: values)

            return CategorySpendingItem(
                id: categoryID ?? UUID(),
                categoryID: categoryID,
                categoryName: categoryName,
                amount: amount,
                percentage: amount / totalExpense,
                colorHex: colorHex,
                iconName: iconName
            )
        }
        .sorted { lhs, rhs in
            if lhs.amount == rhs.amount {
                return lhs.categoryName < rhs.categoryName
            }
            return lhs.amount > rhs.amount
        }

        if items.count > maxVisibleCategories {
            let visible = Array(items.prefix(maxVisibleCategories - 1))
            let remainder = Array(items.dropFirst(maxVisibleCategories - 1))
            let otherAmount = remainder.reduce(0) { $0 + $1.amount }

            let other = CategorySpendingItem(
                id: UUID(uuidString: "D9C56A7D-2AF8-4B6C-A4C2-DA8B46C51001") ?? UUID(),
                categoryID: nil,
                categoryName: "Other",
                amount: otherAmount,
                percentage: otherAmount / totalExpense,
                colorHex: fallbackOtherColorHex,
                iconName: "ellipsis.circle.fill"
            )

            items = visible + [other]
        }

        return CategorySpendingSummary(items: items, totalExpense: totalExpense)
    }

    private static func resolvedCategoryName(
        category: TransactionCategory?,
        transactions: [TransactionItem]
    ) -> String {
        if let category, !category.name.isEmpty {
            return category.name
        }

        if let storedName = transactions.first?.categoryName.trimmingCharacters(in: .whitespacesAndNewlines), !storedName.isEmpty {
            return storedName
        }

        return "Uncategorized"
    }

    private static func resolvedColorHex(
        category: TransactionCategory?,
        transactions: [TransactionItem]
    ) -> String {
        if let colorHex = category?.colorHex, Color(hex: colorHex) != nil {
            return colorHex
        }

        if
            let storedName = transactions.first?.categoryName,
            let fallbackDefinition = TransactionCategoryCatalog.definition(named: storedName),
            Color(hex: fallbackDefinition.colorHex) != nil
        {
            return fallbackDefinition.colorHex
        }

        return fallbackUncategorizedColorHex
    }
}

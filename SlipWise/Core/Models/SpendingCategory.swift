import Foundation
import SwiftData

@Model
final class TransactionCategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var normalizedName: String
    var iconSystemName: String
    var colorHex: String
    var transactionTypeRawValue: String?
    var isSystem: Bool
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        normalizedName: String? = nil,
        iconSystemName: String,
        colorHex: String = "#0F766E",
        transactionTypeRawValue: String? = nil,
        isSystem: Bool = true,
        sortOrder: Int = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.normalizedName = normalizedName ?? name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        self.iconSystemName = iconSystemName
        self.colorHex = colorHex
        self.transactionTypeRawValue = transactionTypeRawValue
        self.isSystem = isSystem
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var transactionType: TransactionType? {
        get {
            guard let transactionTypeRawValue else { return nil }
            return TransactionType(rawValue: transactionTypeRawValue)
        }
        set {
            transactionTypeRawValue = newValue?.rawValue
            updatedAt = .now
        }
    }
}

struct TransactionCategoryDefinition: Identifiable, Hashable {
    let id: UUID
    let name: String
    let iconSystemName: String
    let colorHex: String
    let transactionType: TransactionType?
    let sortOrder: Int
}

enum TransactionCategoryCatalog {
    static let defaultDefinitions: [TransactionCategoryDefinition] = [
        TransactionCategoryDefinition(
            id: UUID(uuidString: "A1D94B52-C37A-4C4F-B84A-4B8B5938A001")!,
            name: "Food & Drink",
            iconSystemName: "fork.knife",
            colorHex: "#F97316",
            transactionType: .expense,
            sortOrder: 0
        ),
        TransactionCategoryDefinition(
            id: UUID(uuidString: "A1D94B52-C37A-4C4F-B84A-4B8B5938A002")!,
            name: "Transport",
            iconSystemName: "car.fill",
            colorHex: "#0EA5E9",
            transactionType: .expense,
            sortOrder: 1
        ),
        TransactionCategoryDefinition(
            id: UUID(uuidString: "A1D94B52-C37A-4C4F-B84A-4B8B5938A003")!,
            name: "Shopping",
            iconSystemName: "bag.fill",
            colorHex: "#8B5CF6",
            transactionType: .expense,
            sortOrder: 2
        ),
        TransactionCategoryDefinition(
            id: UUID(uuidString: "A1D94B52-C37A-4C4F-B84A-4B8B5938A004")!,
            name: "Bills",
            iconSystemName: "doc.text.fill",
            colorHex: "#F43F5E",
            transactionType: .expense,
            sortOrder: 3
        ),
        TransactionCategoryDefinition(
            id: UUID(uuidString: "A1D94B52-C37A-4C4F-B84A-4B8B5938A005")!,
            name: "Entertainment",
            iconSystemName: "film.fill",
            colorHex: "#14B8A6",
            transactionType: .expense,
            sortOrder: 4
        ),
        TransactionCategoryDefinition(
            id: UUID(uuidString: "A1D94B52-C37A-4C4F-B84A-4B8B5938A006")!,
            name: "Health",
            iconSystemName: "heart.fill",
            colorHex: "#EF4444",
            transactionType: .expense,
            sortOrder: 5
        ),
        TransactionCategoryDefinition(
            id: UUID(uuidString: "A1D94B52-C37A-4C4F-B84A-4B8B5938A007")!,
            name: "Salary",
            iconSystemName: "banknote.fill",
            colorHex: "#22C55E",
            transactionType: .income,
            sortOrder: 6
        ),
        TransactionCategoryDefinition(
            id: UUID(uuidString: "A1D94B52-C37A-4C4F-B84A-4B8B5938A008")!,
            name: "Transfer",
            iconSystemName: "arrow.left.arrow.right",
            colorHex: "#64748B",
            transactionType: .transfer,
            sortOrder: 7
        ),
        TransactionCategoryDefinition(
            id: UUID(uuidString: "A1D94B52-C37A-4C4F-B84A-4B8B5938A009")!,
            name: "Other",
            iconSystemName: "square.grid.2x2.fill",
            colorHex: "#94A3B8",
            transactionType: nil,
            sortOrder: 8
        )
    ]

    static func definition(for id: UUID?) -> TransactionCategoryDefinition? {
        guard let id else { return nil }
        return defaultDefinitions.first { $0.id == id }
    }

    static func definition(named name: String?) -> TransactionCategoryDefinition? {
        guard let normalized = name?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines), !normalized.isEmpty else {
            return nil
        }

        return defaultDefinitions.first { $0.name.lowercased() == normalized }
    }

    static func defaultModels() -> [TransactionCategory] {
        defaultDefinitions.map {
            TransactionCategory(
                id: $0.id,
                name: $0.name,
                iconSystemName: $0.iconSystemName,
                colorHex: $0.colorHex,
                transactionTypeRawValue: $0.transactionType?.rawValue,
                isSystem: true,
                sortOrder: $0.sortOrder
            )
        }
    }
}

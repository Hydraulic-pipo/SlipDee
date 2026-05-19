import Foundation
import SwiftData

@Model
final class RecurringIncome {
    @Attribute(.unique) var id: UUID
    var name: String
    var amount: Double
    var currencyCode: String
    var payDay: Int
    var categoryID: UUID?
    var paymentMethodRawValue: String
    var note: String?
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        currencyCode: String = CurrencyCode.thb,
        payDay: Int,
        categoryID: UUID? = nil,
        paymentMethod: PaymentMethod = .bankTransfer,
        note: String? = nil,
        isActive: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.currencyCode = currencyCode
        self.payDay = payDay
        self.categoryID = categoryID
        self.paymentMethodRawValue = paymentMethod.rawValue
        self.note = note
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var paymentMethod: PaymentMethod {
        get { PaymentMethod(rawValue: paymentMethodRawValue) ?? .bankTransfer }
        set {
            paymentMethodRawValue = newValue.rawValue
            touch()
        }
    }

    func touch(at date: Date = .now) {
        updatedAt = date
    }
}

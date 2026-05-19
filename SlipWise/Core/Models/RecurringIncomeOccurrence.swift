import Foundation
import SwiftData

enum RecurringIncomeOccurrenceStatus: String, Codable, CaseIterable, Identifiable {
    case expected
    case confirmed
    case skipped

    var id: String { rawValue }
}

@Model
final class RecurringIncomeOccurrence {
    @Attribute(.unique) var id: UUID
    var recurringIncomeID: UUID
    var month: Int
    var year: Int
    var statusRawValue: String
    var transactionID: UUID?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        recurringIncomeID: UUID,
        month: Int,
        year: Int,
        status: RecurringIncomeOccurrenceStatus,
        transactionID: UUID? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.recurringIncomeID = recurringIncomeID
        self.month = month
        self.year = year
        self.statusRawValue = status.rawValue
        self.transactionID = transactionID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var status: RecurringIncomeOccurrenceStatus {
        get { RecurringIncomeOccurrenceStatus(rawValue: statusRawValue) ?? .expected }
        set {
            statusRawValue = newValue.rawValue
            updatedAt = .now
        }
    }
}

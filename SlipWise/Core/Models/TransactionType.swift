import Foundation

enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case income
    case expense
    case transfer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .income:
            return "Income"
        case .expense:
            return "Expense"
        case .transfer:
            return "Transfer"
        }
    }
}

enum PaymentMethod: String, Codable, CaseIterable, Identifiable {
    case bankTransfer
    case promptPay
    case qrPayment
    case cash
    case card
    case billPayment
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bankTransfer:
            return "Bank Transfer"
        case .promptPay:
            return "PromptPay"
        case .qrPayment:
            return "QR Payment"
        case .cash:
            return "Cash"
        case .card:
            return "Card"
        case .billPayment:
            return "Bill Payment"
        case .other:
            return "Other"
        }
    }
}

enum SlipScanStatus: String, Codable, CaseIterable, Identifiable {
    case pending
    case scanned
    case parsed
    case needsReview
    case failed

    var id: String { rawValue }
}

enum AppLockTimeout: String, Codable, CaseIterable, Identifiable {
    case immediate
    case oneMinute
    case fiveMinutes
    case fifteenMinutes
    case thirtyMinutes
    case never

    var id: String { rawValue }

    var title: String {
        switch self {
        case .immediate:
            return "Immediately"
        case .oneMinute:
            return "After 1 Minute"
        case .fiveMinutes:
            return "After 5 Minutes"
        case .fifteenMinutes:
            return "After 15 Minutes"
        case .thirtyMinutes:
            return "After 30 Minutes"
        case .never:
            return "Never"
        }
    }

    var timeInterval: TimeInterval? {
        switch self {
        case .immediate:
            return 0
        case .oneMinute:
            return 60
        case .fiveMinutes:
            return 300
        case .fifteenMinutes:
            return 900
        case .thirtyMinutes:
            return 1_800
        case .never:
            return nil
        }
    }
}

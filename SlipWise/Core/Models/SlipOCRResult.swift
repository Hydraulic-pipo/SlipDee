import Foundation

struct ParsedSlip: Identifiable, Hashable {
    var id: UUID = UUID()
    var amount: Double?
    var currencyCode: String
    var type: TransactionType
    var paymentMethod: PaymentMethod?
    var categoryID: UUID?
    var categoryName: String
    var categoryIconName: String
    var bankName: String?
    var receiverName: String?
    var senderName: String?
    var transactionReference: String?
    var transactionDate: Date?
    var transactionTimeText: String?
    var transferType: String?
    var note: String
    var recognizedTextLines: [String]
    var sourceImageName: String?
    var status: SlipScanStatus

    init(
        id: UUID = UUID(),
        amount: Double? = nil,
        currencyCode: String = CurrencyCode.thb,
        type: TransactionType = .expense,
        paymentMethod: PaymentMethod? = nil,
        categoryID: UUID? = nil,
        categoryName: String = "Other",
        categoryIconName: String = "square.grid.2x2.fill",
        bankName: String? = nil,
        receiverName: String? = nil,
        senderName: String? = nil,
        transactionReference: String? = nil,
        transactionDate: Date? = nil,
        transactionTimeText: String? = nil,
        transferType: String? = nil,
        note: String = "",
        recognizedTextLines: [String] = [],
        sourceImageName: String? = nil,
        status: SlipScanStatus = .pending
    ) {
        self.id = id
        self.amount = amount
        self.currencyCode = currencyCode
        self.type = type
        self.paymentMethod = paymentMethod
        self.categoryID = categoryID
        self.categoryName = categoryName
        self.categoryIconName = categoryIconName
        self.bankName = bankName
        self.receiverName = receiverName
        self.senderName = senderName
        self.transactionReference = transactionReference
        self.transactionDate = transactionDate
        self.transactionTimeText = transactionTimeText
        self.transferType = transferType
        self.note = note
        self.recognizedTextLines = recognizedTextLines
        self.sourceImageName = sourceImageName
        self.status = status
    }
}

typealias SlipOCRResult = ParsedSlip

struct MonthlySummary: Identifiable, Hashable {
    var id: String { "\(year)-\(month)-\(currencyCode)" }
    let month: Int
    let year: Int
    let incomeTotal: Double
    let expenseTotal: Double
    let balance: Double
    let transactionCount: Int
    let currencyCode: String
}

struct CategoryBreakdown: Identifiable, Hashable {
    let id: UUID
    let categoryID: UUID?
    let categoryName: String
    let iconSystemName: String
    let totalAmount: Double
    let transactionCount: Int
    let percentage: Double
    let currencyCode: String
}

struct DailySpending: Identifiable, Hashable {
    var id: Date { date }
    let date: Date
    let totalAmount: Double
    let transactionCount: Int
    let currencyCode: String
}

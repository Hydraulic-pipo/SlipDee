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
    var rawOCRText: String
    var ocrConfidence: Double?
    var reviewStatus: ScannedSlipStatus
    var duplicateReason: String?
    var originalFileName: String?
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
        rawOCRText: String = "",
        ocrConfidence: Double? = nil,
        reviewStatus: ScannedSlipStatus = .new,
        duplicateReason: String? = nil,
        originalFileName: String? = nil,
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
        self.rawOCRText = rawOCRText
        self.ocrConfidence = ocrConfidence
        self.reviewStatus = reviewStatus
        self.duplicateReason = duplicateReason
        self.originalFileName = originalFileName
        self.sourceImageName = sourceImageName
        self.status = status
    }
}

enum ScannedSlipStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case new
    case duplicate
    case notRecognized
    case failed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .new:
            return "New"
        case .duplicate:
            return "Duplicate"
        case .notRecognized:
            return "Not recognized"
        case .failed:
            return "Failed"
        }
    }
}

struct ScannedSlipResult: Identifiable {
    let id: UUID
    let imageData: Data?
    let rawOCRText: String
    let isLikelySlip: Bool
    let status: ScannedSlipStatus
    let duplicateReason: String?
    let parsedSlip: ParsedSlip
    let createdAt: Date

    init(
        id: UUID = UUID(),
        imageData: Data?,
        rawOCRText: String,
        isLikelySlip: Bool,
        status: ScannedSlipStatus,
        duplicateReason: String? = nil,
        parsedSlip: ParsedSlip,
        createdAt: Date = .now
    ) {
        self.id = id
        self.imageData = imageData
        self.rawOCRText = rawOCRText
        self.isLikelySlip = isLikelySlip
        self.status = status
        self.duplicateReason = duplicateReason
        self.parsedSlip = parsedSlip
        self.createdAt = createdAt
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

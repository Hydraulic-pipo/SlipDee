import Foundation
import SwiftData

@Model
final class TransactionItem {
    @Attribute(.unique) var id: UUID
    var slipRecordID: UUID?
    var categoryID: UUID?
    var merchantRuleID: UUID?
    var amount: Double
    var currencyCode: String
    var typeRawValue: String
    var paymentMethodRawValue: String
    var categoryName: String
    var categoryIconName: String
    var merchantName: String
    var bankName: String
    var receiverName: String
    var senderName: String
    var transactionReference: String
    var transactionDate: Date
    var note: String
    var isFromSlip: Bool
    var isDuplicateSuspected: Bool
    var sourceImageName: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        slipRecordID: UUID? = nil,
        categoryID: UUID? = nil,
        merchantRuleID: UUID? = nil,
        amount: Double,
        currencyCode: String = CurrencyCode.thb,
        typeRawValue: String = TransactionType.expense.rawValue,
        paymentMethodRawValue: String = PaymentMethod.other.rawValue,
        categoryName: String = "Other",
        categoryIconName: String = "square.grid.2x2.fill",
        merchantName: String = "",
        bankName: String = "",
        receiverName: String = "",
        senderName: String = "",
        transactionReference: String = "",
        transactionDate: Date,
        note: String = "",
        isFromSlip: Bool = false,
        isDuplicateSuspected: Bool = false,
        sourceImageName: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.slipRecordID = slipRecordID
        self.categoryID = categoryID
        self.merchantRuleID = merchantRuleID
        self.amount = amount
        self.currencyCode = currencyCode
        self.typeRawValue = typeRawValue
        self.paymentMethodRawValue = paymentMethodRawValue
        self.categoryName = categoryName
        self.categoryIconName = categoryIconName
        self.merchantName = merchantName
        self.bankName = bankName
        self.receiverName = receiverName
        self.senderName = senderName
        self.transactionReference = transactionReference
        self.transactionDate = transactionDate
        self.note = note
        self.isFromSlip = isFromSlip
        self.isDuplicateSuspected = isDuplicateSuspected
        self.sourceImageName = sourceImageName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    convenience init(
        id: UUID = UUID(),
        slipRecordID: UUID? = nil,
        categoryDefinition: TransactionCategoryDefinition?,
        merchantRuleID: UUID? = nil,
        amount: Double,
        currencyCode: String = CurrencyCode.thb,
        type: TransactionType,
        paymentMethod: PaymentMethod = .other,
        merchantName: String = "",
        bankName: String = "",
        receiverName: String = "",
        senderName: String = "",
        transactionReference: String = "",
        transactionDate: Date,
        note: String = "",
        isFromSlip: Bool = false,
        isDuplicateSuspected: Bool = false,
        sourceImageName: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.init(
            id: id,
            slipRecordID: slipRecordID,
            categoryID: categoryDefinition?.id,
            merchantRuleID: merchantRuleID,
            amount: amount,
            currencyCode: currencyCode,
            typeRawValue: type.rawValue,
            paymentMethodRawValue: paymentMethod.rawValue,
            categoryName: categoryDefinition?.name ?? "Other",
            categoryIconName: categoryDefinition?.iconSystemName ?? "square.grid.2x2.fill",
            merchantName: merchantName,
            bankName: bankName,
            receiverName: receiverName,
            senderName: senderName,
            transactionReference: transactionReference,
            transactionDate: transactionDate,
            note: note,
            isFromSlip: isFromSlip,
            isDuplicateSuspected: isDuplicateSuspected,
            sourceImageName: sourceImageName,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    var type: TransactionType {
        get { TransactionType(rawValue: typeRawValue) ?? .expense }
        set {
            typeRawValue = newValue.rawValue
            touch()
        }
    }

    var paymentMethod: PaymentMethod {
        get { PaymentMethod(rawValue: paymentMethodRawValue) ?? .other }
        set {
            paymentMethodRawValue = newValue.rawValue
            touch()
        }
    }

    func applyCategory(_ definition: TransactionCategoryDefinition?) {
        categoryID = definition?.id
        categoryName = definition?.name ?? "Other"
        categoryIconName = definition?.iconSystemName ?? "square.grid.2x2.fill"
        touch()
    }

    func touch(at date: Date = .now) {
        updatedAt = date
    }

    var displayName: String {
        if !merchantName.isEmpty { return merchantName }
        if !receiverName.isEmpty { return receiverName }
        if !senderName.isEmpty { return senderName }
        return "Untitled Transaction"
    }
}

@Model
final class SlipRecord {
    @Attribute(.unique) var id: UUID
    var originalFileName: String
    var storedImageName: String?
    var recognizedText: String
    var currencyCode: String
    var scanStatusRawValue: String
    var detectedAmount: Double?
    var detectedTransactionDate: Date?
    var detectedMerchantName: String
    var scannedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        originalFileName: String = "",
        storedImageName: String? = nil,
        recognizedText: String = "",
        currencyCode: String = CurrencyCode.thb,
        scanStatusRawValue: String = SlipScanStatus.pending.rawValue,
        detectedAmount: Double? = nil,
        detectedTransactionDate: Date? = nil,
        detectedMerchantName: String = "",
        scannedAt: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.originalFileName = originalFileName
        self.storedImageName = storedImageName
        self.recognizedText = recognizedText
        self.currencyCode = currencyCode
        self.scanStatusRawValue = scanStatusRawValue
        self.detectedAmount = detectedAmount
        self.detectedTransactionDate = detectedTransactionDate
        self.detectedMerchantName = detectedMerchantName
        self.scannedAt = scannedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var scanStatus: SlipScanStatus {
        get { SlipScanStatus(rawValue: scanStatusRawValue) ?? .pending }
        set {
            scanStatusRawValue = newValue.rawValue
            updatedAt = .now
        }
    }
}

@Model
final class Budget {
    @Attribute(.unique) var id: UUID
    var categoryID: UUID?
    var name: String
    var amountLimit: Double
    var currencyCode: String
    var periodStart: Date
    var periodEnd: Date
    var isRecurring: Bool
    var isActive: Bool
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        categoryID: UUID? = nil,
        name: String,
        amountLimit: Double,
        currencyCode: String = CurrencyCode.thb,
        periodStart: Date,
        periodEnd: Date,
        isRecurring: Bool = true,
        isActive: Bool = true,
        notes: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.categoryID = categoryID
        self.name = name
        self.amountLimit = amountLimit
        self.currencyCode = currencyCode
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.isRecurring = isRecurring
        self.isActive = isActive
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class MerchantRule {
    @Attribute(.unique) var id: UUID
    var merchantName: String
    var normalizedMerchantName: String
    var categoryID: UUID?
    var transactionTypeRawValue: String
    var paymentMethodRawValue: String?
    var isActive: Bool
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        merchantName: String,
        normalizedMerchantName: String? = nil,
        categoryID: UUID? = nil,
        transactionTypeRawValue: String = TransactionType.expense.rawValue,
        paymentMethodRawValue: String? = nil,
        isActive: Bool = true,
        notes: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.merchantName = merchantName
        self.normalizedMerchantName = normalizedMerchantName ?? merchantName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        self.categoryID = categoryID
        self.transactionTypeRawValue = transactionTypeRawValue
        self.paymentMethodRawValue = paymentMethodRawValue
        self.isActive = isActive
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var transactionType: TransactionType {
        get { TransactionType(rawValue: transactionTypeRawValue) ?? .expense }
        set {
            transactionTypeRawValue = newValue.rawValue
            updatedAt = .now
        }
    }

    var paymentMethod: PaymentMethod? {
        get {
            guard let paymentMethodRawValue else { return nil }
            return PaymentMethod(rawValue: paymentMethodRawValue)
        }
        set {
            paymentMethodRawValue = newValue?.rawValue
            updatedAt = .now
        }
    }
}

@Model
final class UserSettings {
    @Attribute(.unique) var id: UUID
    var defaultCurrencyCode: String
    var isBiometricUnlockEnabled: Bool
    var isAppLockEnabled: Bool
    var isEditProtectionEnabled: Bool
    var isDeleteProtectionEnabled: Bool
    var isEditDeletePasswordEnabled: Bool
    var editDeletePasswordHash: String?
    var isBiometricEditDeleteEnabled: Bool
    var appLockTimeoutRawValue: String
    var preferredFirstWeekday: Int
    var areNotificationsEnabled: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        defaultCurrencyCode: String = CurrencyCode.thb,
        isBiometricUnlockEnabled: Bool = false,
        isAppLockEnabled: Bool = false,
        isEditProtectionEnabled: Bool = false,
        isDeleteProtectionEnabled: Bool = false,
        isEditDeletePasswordEnabled: Bool = false,
        editDeletePasswordHash: String? = nil,
        isBiometricEditDeleteEnabled: Bool = false,
        appLockTimeoutRawValue: String = AppLockTimeout.immediate.rawValue,
        preferredFirstWeekday: Int = 2,
        areNotificationsEnabled: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.defaultCurrencyCode = defaultCurrencyCode
        self.isBiometricUnlockEnabled = isBiometricUnlockEnabled
        self.isAppLockEnabled = isAppLockEnabled
        self.isEditProtectionEnabled = isEditProtectionEnabled
        self.isDeleteProtectionEnabled = isDeleteProtectionEnabled
        self.isEditDeletePasswordEnabled = isEditDeletePasswordEnabled
        self.editDeletePasswordHash = editDeletePasswordHash
        self.isBiometricEditDeleteEnabled = isBiometricEditDeleteEnabled
        self.appLockTimeoutRawValue = appLockTimeoutRawValue
        self.preferredFirstWeekday = preferredFirstWeekday
        self.areNotificationsEnabled = areNotificationsEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var appLockTimeout: AppLockTimeout {
        get { AppLockTimeout(rawValue: appLockTimeoutRawValue) ?? .immediate }
        set {
            appLockTimeoutRawValue = newValue.rawValue
            updatedAt = .now
        }
    }

    var isEditDeleteProtectionEnabled: Bool {
        isEditProtectionEnabled || isDeleteProtectionEnabled
    }

    func touch(at date: Date = .now) {
        updatedAt = date
    }
}

enum CurrencyCode {
    static let thb = "THB"
}

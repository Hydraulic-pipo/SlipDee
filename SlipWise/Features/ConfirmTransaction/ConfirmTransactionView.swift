import SwiftData
import SwiftUI

struct ConfirmTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var amountText: String
    @State private var transactionType: TransactionType
    @State private var selectedCategoryID: UUID
    @State private var bankName: String
    @State private var receiverName: String
    @State private var transactionReference: String
    @State private var transactionDate: Date
    @State private var note: String
    @State private var sourceImageName: String?
    @State private var paymentMethod: PaymentMethod

    private let recognizedLines: [String]
    private let reviewStatus: ScannedSlipStatus
    private let duplicateReason: String?
    private let rawOCRText: String
    private let ocrConfidence: Double?
    private let originalFileName: String?

    init(initialResult: ParsedSlip) {
        let initialCategory = TransactionCategoryCatalog.definition(for: initialResult.categoryID)
            ?? TransactionCategoryCatalog.definition(named: initialResult.categoryName)
            ?? TransactionCategoryCatalog.definition(named: "Other")
            ?? TransactionCategoryCatalog.defaultDefinitions[0]
        _amountText = State(initialValue: initialResult.amount.map { String(format: "%.2f", $0) } ?? "")
        _transactionType = State(initialValue: initialResult.type)
        _selectedCategoryID = State(initialValue: initialCategory.id)
        _bankName = State(initialValue: initialResult.bankName ?? "")
        _receiverName = State(initialValue: initialResult.receiverName ?? "")
        _transactionReference = State(initialValue: initialResult.transactionReference ?? "")
        _transactionDate = State(initialValue: initialResult.transactionDate ?? .now)
        _note = State(initialValue: initialResult.note)
        _sourceImageName = State(initialValue: initialResult.sourceImageName)
        _paymentMethod = State(initialValue: initialResult.paymentMethod ?? .other)
        recognizedLines = initialResult.recognizedTextLines
        reviewStatus = initialResult.reviewStatus
        duplicateReason = initialResult.duplicateReason
        rawOCRText = initialResult.rawOCRText
        ocrConfidence = initialResult.ocrConfidence
        originalFileName = initialResult.originalFileName
    }

    var body: some View {
        AppScreen {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    confidencePill
                    if reviewStatus != .new {
                        reviewBanner
                    }
                    amountHeader
                    detailCard

                    if !recognizedLines.isEmpty || !rawOCRText.isEmpty {
                        recognizedTextCard
                    }

                    Button("Save Transaction") {
                        saveTransaction()
                    }
                    .buttonStyle(PrimaryFintechButtonStyle())
                    .disabled(parsedAmount == nil)
                }
                .padding(.horizontal, AppSpacing.page)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Confirm Transaction")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var confidencePill: some View {
        Text("OCR Confidence \(Int((ocrConfidence ?? 0.95) * 100))%")
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppColors.darkTeal)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppColors.softMint)
            .clipShape(Capsule())
    }

    private var reviewBanner: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(reviewStatus == .duplicate ? "Possible Duplicate" : "Needs Manual Review")
                    .font(.headline)
                    .foregroundStyle(reviewStatus == .duplicate ? AppColors.warning : AppColors.expense)

                Text(duplicateReason ?? "Please review the OCR details carefully before saving.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
    }

    private var amountHeader: some View {
        VStack(spacing: 10) {
            Text("Amount")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.secondaryText)

            Text(parsedAmount.map(CurrencyFormatter.bahtString(from:)) ?? "฿0.00")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryText)
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
    }

    private var detailCard: some View {
        AppCard {
            VStack(spacing: 0) {
                detailPickerRow(icon: "square.grid.2x2", label: "Category") {
                    Picker("Category", selection: $selectedCategoryID) {
                        ForEach(availableCategories) { category in
                            Text(category.name).tag(category.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppColors.primaryText)
                }

                divider

                detailInputRow(icon: "bahtsign.circle", label: "Amount", text: $amountText, keyboardType: .decimalPad)

                divider

                detailPickerRow(icon: "arrow.left.arrow.right", label: "Type") {
                    Picker("Type", selection: $transactionType) {
                        ForEach(TransactionType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppColors.primaryText)
                }

                divider

                detailInputRow(icon: "building.columns", label: "Bank", text: $bankName)

                divider

                detailInputRow(icon: "person", label: "Receiver", text: $receiverName)

                divider

                detailDateRow

                divider

                detailInputRow(icon: "number", label: "Reference No.", text: $transactionReference)

                divider

                detailPickerRow(icon: "creditcard", label: "Payment Method") {
                    Picker("Payment Method", selection: $paymentMethod) {
                        ForEach(PaymentMethod.allCases) { method in
                            Text(method.title).tag(method)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppColors.primaryText)
                }

                divider

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Note Optional", systemImage: "note.text")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppColors.primaryText)
                        Spacer()
                    }

                    TextField("Add a short note", text: $note, axis: .vertical)
                        .foregroundStyle(AppColors.primaryText)
                        .padding(14)
                        .background(AppColors.elevatedCardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous))
                }
                .padding(.top, 16)
            }
        }
    }

    private var detailDateRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Date & Time", systemImage: "calendar")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.primaryText)

            DatePicker(
                "Transaction Date",
                selection: $transactionDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .tint(AppColors.primaryTeal)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
    }

    private var recognizedTextCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Recognized Text")
                    .font(.headline)
                    .foregroundStyle(AppColors.primaryText)

                ForEach(recognizedTextLines, id: \.self) { line in
                    Text(line)
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.elevatedCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    private var parsedAmount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: ""))
    }

    private var availableCategories: [TransactionCategoryDefinition] {
        let filtered = TransactionCategoryCatalog.defaultDefinitions.filter { definition in
            definition.transactionType == nil || definition.transactionType == transactionType
        }

        return filtered.isEmpty ? TransactionCategoryCatalog.defaultDefinitions : filtered
    }

    private var divider: some View {
        Divider()
            .overlay(AppColors.border)
    }

    private func detailInputRow(
        icon: String,
        label: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(AppColors.primaryTeal)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.secondaryText)

                TextField(label, text: text)
                    .keyboardType(keyboardType)
                    .foregroundStyle(AppColors.primaryText)
            }

            Spacer()
        }
        .padding(.vertical, 16)
    }

    private func detailPickerRow<Content: View>(icon: String, label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(AppColors.primaryTeal)
                .frame(width: 20)

            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.primaryText)

            Spacer()

            content()
        }
        .padding(.vertical, 16)
    }

    private func saveTransaction() {
        guard let parsedAmount else { return }
        let selectedCategory = TransactionCategoryCatalog.definition(for: selectedCategoryID)
        let slipRecord = SlipRecord(
            originalFileName: originalFileName ?? sourceImageName ?? "",
            storedImageName: sourceImageName,
            recognizedText: rawOCRText.isEmpty ? recognizedLines.joined(separator: "\n") : rawOCRText,
            currencyCode: CurrencyCode.thb,
            scanStatusRawValue: slipRecordStatus.rawValue,
            detectedAmount: parsedAmount,
            detectedTransactionDate: transactionDate,
            detectedBankName: bankName,
            detectedReceiverName: receiverName,
            detectedReferenceNumber: transactionReference,
            detectedMerchantName: receiverName,
            confidenceScore: ocrConfidence,
            scannedAt: .now
        )

        modelContext.insert(slipRecord)

        let transaction = TransactionItem(
            slipRecordID: slipRecord.id,
            categoryDefinition: selectedCategory,
            amount: parsedAmount,
            type: transactionType,
            paymentMethod: paymentMethod,
            merchantName: receiverName,
            bankName: bankName,
            receiverName: receiverName,
            senderName: "",
            transactionReference: transactionReference,
            transactionDate: transactionDate,
            note: note,
            isFromSlip: true,
            isDuplicateSuspected: reviewStatus == .duplicate,
            sourceImageName: sourceImageName,
            createdAt: .now,
            updatedAt: .now
        )

        modelContext.insert(transaction)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save transaction: \(error)")
        }
    }

    private var recognizedTextLines: [String] {
        if !recognizedLines.isEmpty {
            return recognizedLines
        }

        return rawOCRText
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    private var slipRecordStatus: SlipScanStatus {
        switch reviewStatus {
        case .new, .duplicate:
            return .needsReview
        case .notRecognized, .failed:
            return .failed
        }
    }
}

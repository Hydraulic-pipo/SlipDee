import SwiftUI

struct SlipScanResultRowView: View {
    @AppStorage(AppSettingsKey.isHideAmountsEnabled) private var isHideAmountsEnabled = false

    let result: ScannedSlipResult

    var body: some View {
        AppCard {
            HStack(alignment: .top, spacing: 14) {
                thumbnailView

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Text(displayTitle)
                            .font(.headline)
                            .foregroundStyle(AppColors.primaryText)
                            .lineLimit(2)

                        Spacer(minLength: 8)

                        statusBadge
                    }

                    Text(result.parsedSlip.bankName ?? "Bank not detected")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)

                    HStack(spacing: 8) {
                        Text(dateText)
                        Text("•")
                        Text(receiverText)
                    }
                    .font(.caption)
                    .foregroundStyle(AppColors.mutedText)
                    .lineLimit(1)

                    if let duplicateReason = result.duplicateReason, !duplicateReason.isEmpty {
                        Text(duplicateReason)
                            .font(.caption)
                            .foregroundStyle(statusColor)
                            .lineLimit(2)
                    }

                    Text(confidenceText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
        }
    }

    private var thumbnailView: some View {
        Group {
            if let image = result.imageData.flatMap(UIImage.init(data:)) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "doc.text.image")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppColors.primaryTeal)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColors.softTealBackground)
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var displayTitle: String {
        if let amount = result.parsedSlip.amount {
            return AmountDisplayFormatter.display(
                amount: amount,
                isHidden: isHideAmountsEnabled
            )
        }

        return "Amount not detected"
    }

    private var dateText: String {
        if let date = result.parsedSlip.transactionDate {
            return DateParsers.shortDateTime.string(from: date)
        }

        return "Date not detected"
    }

    private var receiverText: String {
        if let receiverName = result.parsedSlip.receiverName, !receiverName.isEmpty {
            return receiverName
        }

        return "Receiver not detected"
    }

    private var confidenceText: String {
        let percentage = Int((result.parsedSlip.ocrConfidence ?? 0) * 100)
        return "OCR confidence \(percentage)%"
    }

    private var statusBadge: some View {
        Text(result.status.title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(statusColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.12))
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch result.status {
        case .new:
            return AppColors.primaryTeal
        case .duplicate:
            return AppColors.warning
        case .notRecognized:
            return AppColors.mutedText
        case .failed:
            return AppColors.expense
        }
    }
}

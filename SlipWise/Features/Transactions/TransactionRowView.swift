import SwiftUI

struct TransactionRowView: View {
    let transaction: TransactionItem
    var showsDisclosure = false

    private var amountColor: Color {
        switch transaction.type {
        case .income:
            return AppColors.income
        case .expense:
            return AppColors.expense
        case .transfer:
            return AppColors.darkTeal
        }
    }

    private var badgeBackground: Color {
        switch transaction.type {
        case .income:
            return AppColors.income.opacity(0.12)
        case .expense:
            return AppColors.expense.opacity(0.12)
        case .transfer:
            return AppColors.softMint
        }
    }

    var body: some View {
        AppCard {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: transaction.categoryIconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.primaryTeal)
                    .frame(width: 42, height: 42)
                    .background(AppColors.softMint)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(transaction.displayName)
                        .font(.headline)
                        .foregroundStyle(AppColors.primaryText)

                    Text(transaction.categoryName.isEmpty ? "Manual transaction" : transaction.categoryName)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)

                    HStack(spacing: 8) {
                        Text(DateParsers.shortDateTime.string(from: transaction.transactionDate))
                            .font(.caption)
                            .foregroundStyle(AppColors.mutedText)

                        Text("•")
                            .foregroundStyle(AppColors.mutedText)

                        Text(transaction.paymentMethod.title)
                            .font(.caption)
                            .foregroundStyle(AppColors.mutedText)
                    }
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 8) {
                    Text(CurrencyFormatter.bahtString(from: transaction.amount))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(amountColor)

                    Text(transaction.type.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(amountColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(badgeBackground)
                        .clipShape(Capsule())
                }

                if showsDisclosure {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColors.mutedText)
                        .padding(.top, 6)
                }
            }
        }
    }
}

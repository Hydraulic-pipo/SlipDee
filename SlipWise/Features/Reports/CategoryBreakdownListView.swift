import SwiftUI

struct CategoryBreakdownListView: View {
    let items: [CategorySpendingItem]

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Category Breakdown")
                    .font(.headline)
                    .foregroundStyle(AppColors.primaryText)

                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    VStack(spacing: 10) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(categoryColor(for: item).opacity(0.16))
                                    .frame(width: 34, height: 34)

                                Image(systemName: item.iconName)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(categoryColor(for: item))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.categoryName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppColors.primaryText)

                                Text(CurrencyFormatter.bahtString(from: item.amount))
                                    .font(.caption)
                                    .foregroundStyle(AppColors.secondaryText)
                            }

                            Spacer()

                            Text("\((item.percentage * 100).formatted(.number.precision(.fractionLength(0))))%")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppColors.primaryText)
                        }

                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(AppColors.border.opacity(0.75))

                                Capsule()
                                    .fill(categoryColor(for: item))
                                    .frame(width: max(12, proxy.size.width * item.percentage))
                            }
                        }
                        .frame(height: 8)
                    }

                    if index < items.count - 1 {
                        Divider()
                            .overlay(AppColors.border)
                            .padding(.top, 6)
                    }
                }
            }
        }
    }

    private func categoryColor(for item: CategorySpendingItem) -> Color {
        Color(hex: item.colorHex) ?? AppColors.primaryTeal
    }
}

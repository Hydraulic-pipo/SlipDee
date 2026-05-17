import Charts
import SwiftUI

struct CategoryDonutChartView: View {
    let summary: CategorySpendingSummary
    var isHideAmountsEnabled = false

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Spending by Category")
                    .font(.headline)
                    .foregroundStyle(AppColors.primaryText)

                ZStack {
                    Chart(summary.items) { item in
                        SectorMark(
                            angle: .value("Amount", item.amount),
                            innerRadius: .ratio(0.62),
                            angularInset: 2
                        )
                        .foregroundStyle(categoryColor(for: item))
                        .cornerRadius(6)
                    }
                    .chartLegend(.hidden)
                    .frame(height: 260)

                    VStack(spacing: 6) {
                        Text("Total")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.secondaryText)

                        Text(AmountDisplayFormatter.display(amount: summary.totalExpense, isHidden: isHideAmountsEnabled))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColors.primaryText)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.75)
                    }
                }
            }
        }
    }

    private func categoryColor(for item: CategorySpendingItem) -> Color {
        Color(hex: item.colorHex) ?? AppColors.primaryTeal
    }
}

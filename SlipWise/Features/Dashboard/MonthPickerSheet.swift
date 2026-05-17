import SwiftUI

struct MonthPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedMonth: Int
    @Binding var selectedYear: Int

    @State private var displayYear: Int

    private let monthSymbols: [String]

    init(selectedMonth: Binding<Int>, selectedYear: Binding<Int>) {
        self._selectedMonth = selectedMonth
        self._selectedYear = selectedYear
        self._displayYear = State(initialValue: selectedYear.wrappedValue)

        let formatter = DateFormatter()
        formatter.locale = .current
        self.monthSymbols = formatter.shortMonthSymbols
    }

    var body: some View {
        NavigationStack {
            AppScreen {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    HStack {
                        Button {
                            displayYear -= 1
                        } label: {
                            yearControlIcon("chevron.left")
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Text("\(displayYear)")
                            .font(.title3.bold())
                            .foregroundStyle(AppColors.primaryText)

                        Spacer()

                        Button {
                            displayYear += 1
                        } label: {
                            yearControlIcon("chevron.right")
                        }
                        .buttonStyle(.plain)
                    }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                        ForEach(Array(monthSymbols.enumerated()), id: \.offset) { index, symbol in
                            let monthNumber = index + 1

                            Button {
                                selectedMonth = monthNumber
                                selectedYear = displayYear
                                dismiss()
                            } label: {
                                Text(symbol)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(isSelected(month: monthNumber) ? Color.white : AppColors.primaryText)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(isSelected(month: monthNumber) ? AppColors.primaryTeal : AppColors.cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous)
                                            .stroke(isSelected(month: monthNumber) ? AppColors.primaryTeal : AppColors.border, lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, AppSpacing.page)
                .padding(.top, 20)
                .padding(.bottom, 28)
            }
            .navigationTitle("Select Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppColors.secondaryText)
                }
            }
        }
    }

    private func isSelected(month: Int) -> Bool {
        selectedMonth == month && selectedYear == displayYear
    }

    private func yearControlIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppColors.primaryText)
            .frame(width: 40, height: 40)
            .background(AppColors.cardBackground)
            .overlay(
                Circle()
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .clipShape(Circle())
    }
}

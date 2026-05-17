import SwiftUI

private struct SupportedBank: Identifiable {
    let id = UUID()
    let name: String
    let status: String
}

struct SupportedBanksView: View {
    private let banks: [SupportedBank] = [
        SupportedBank(name: "KBank", status: "Coming soon"),
        SupportedBank(name: "SCB", status: "Coming soon"),
        SupportedBank(name: "Bangkok Bank", status: "Coming soon"),
        SupportedBank(name: "Krungthai", status: "Coming soon"),
        SupportedBank(name: "Krungsri", status: "Coming soon"),
        SupportedBank(name: "TTB", status: "Coming soon"),
        SupportedBank(name: "GSB", status: "Coming soon"),
        SupportedBank(name: "TrueMoney Wallet", status: "Coming soon"),
        SupportedBank(name: "PromptPay", status: "Coming soon"),
        SupportedBank(name: "Manual entry", status: "Supported")
    ]

    var body: some View {
        AppScreen {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    Text("Supported Banks")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)

                    Text("SlipDee currently supports manual transaction tracking, while bank-specific slip parsing is still being expanded.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)

                    AppCard {
                        VStack(spacing: 0) {
                            ForEach(Array(banks.enumerated()), id: \.element.id) { index, bank in
                                SettingsRowView(
                                    icon: "building.columns",
                                    title: bank.name,
                                    trailingText: bank.status,
                                    showsChevron: false
                                )
                                .padding(.vertical, 10)

                                if index < banks.count - 1 {
                                    Divider()
                                        .overlay(AppColors.border)
                                        .padding(.leading, 48)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.page)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Supported Banks")
        .navigationBarTitleDisplayMode(.inline)
    }
}

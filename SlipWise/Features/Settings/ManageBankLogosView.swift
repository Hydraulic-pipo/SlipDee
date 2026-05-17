import SwiftUI

struct ManageBankLogosView: View {
    var body: some View {
        AppScreen {
            VStack(spacing: AppSpacing.section) {
                Spacer()

                AppCard {
                    VStack(spacing: 14) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(AppColors.primaryTeal)

                        Text("Manage Bank Logos")
                            .font(.title3.bold())
                            .foregroundStyle(AppColors.primaryText)

                        Text("Custom bank logo management is coming soon.")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, AppSpacing.page)

                Spacer()
            }
        }
        .navigationTitle("Bank Logos")
        .navigationBarTitleDisplayMode(.inline)
    }
}

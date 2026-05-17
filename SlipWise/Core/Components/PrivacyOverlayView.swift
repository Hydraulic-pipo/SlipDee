import SwiftUI

struct PrivacyOverlayView: View {
    let title: String
    let message: String
    var buttonTitle: String?
    var systemImage: String = "lock.shield"
    var action: (() -> Void)?

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.section) {
                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColors.primaryTeal)
                    .frame(width: 64, height: 64)
                    .background(AppColors.softTealBackground)
                    .clipShape(Circle())

                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                }

                if let buttonTitle, let action {
                    Button(buttonTitle, action: action)
                        .buttonStyle(PrimaryFintechButtonStyle())
                        .frame(maxWidth: 240)
                }
            }
            .padding(.horizontal, AppSpacing.page)
        }
    }
}

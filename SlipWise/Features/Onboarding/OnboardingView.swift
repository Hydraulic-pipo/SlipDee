import SwiftUI

struct OnboardingView: View {
    let onGetStarted: () -> Void

    var body: some View {
        AppScreen {
            VStack(spacing: 0) {
                Spacer(minLength: 48)

                logoHeader

                Spacer(minLength: 32)

                slipIllustration

                Spacer()

                VStack(spacing: 20) {
                    HStack(spacing: 8) {
                        pageDot(active: true)
                        pageDot(active: false)
                        pageDot(active: false)
                    }

                    Button("Get Started", action: onGetStarted)
                        .buttonStyle(PrimaryFintechButtonStyle())
                }
                .padding(.horizontal, AppSpacing.page)
                .padding(.bottom, 30)
            }
        }
    }

    private var logoHeader: some View {
        VStack(spacing: 18) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppColors.softMint)
                        .frame(width: 58, height: 58)

                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(AppColors.darkTeal)
                }

                Text("SlipDee")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryText)
            }

            Text("Track spending\nfrom Thai bank slips")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryText)
                .multilineTextAlignment(.center)

            Text("Simple, private, and easy to trust.")
                .font(.subheadline)
                .foregroundStyle(AppColors.secondaryText)
        }
        .padding(.horizontal, AppSpacing.page)
    }

    private var slipIllustration: some View {
        ZStack {
            Circle()
                .fill(AppColors.softMint.opacity(0.45))
                .frame(width: 260, height: 260)
                .offset(x: -60, y: -20)

            AppCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(AppColors.primaryTeal.opacity(0.12))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "building.columns")
                                    .foregroundStyle(AppColors.primaryTeal)
                            )

                        Spacer()

                        Text("THB")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.secondaryText)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppColors.background)
                            .clipShape(Capsule())
                    }

                    Text("Bangkok Bank")
                        .font(.headline)
                        .foregroundStyle(AppColors.primaryText)

                    Text("Transfer received")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)

                    Divider()

                    HStack {
                        Text("Amount")
                            .foregroundStyle(AppColors.secondaryText)
                        Spacer()
                        Text("฿2,500.00")
                            .font(.title3.bold())
                            .foregroundStyle(AppColors.primaryText)
                    }

                    HStack {
                        Text("Receiver")
                            .foregroundStyle(AppColors.secondaryText)
                        Spacer()
                        Text("Ploy Market")
                            .foregroundStyle(AppColors.primaryText)
                    }
                }
            }
            .frame(maxWidth: 320)
        }
        .padding(.horizontal, AppSpacing.page)
    }

    private func pageDot(active: Bool) -> some View {
        Circle()
            .fill(active ? AppColors.primaryTeal : AppColors.border)
            .frame(width: active ? 10 : 8, height: active ? 10 : 8)
    }
}

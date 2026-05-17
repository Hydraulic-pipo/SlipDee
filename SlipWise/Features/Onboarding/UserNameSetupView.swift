import SwiftUI

struct UserNameSetupView: View {
    @AppStorage(AppSettingsKey.userDisplayName) private var userDisplayName = ""
    @AppStorage(AppSettingsKey.hasCompletedNameSetup) private var hasCompletedNameSetup = false
    @AppStorage(AppSettingsKey.hasCompletedSecuritySetup) private var hasCompletedSecuritySetup = false
    @AppStorage(AppSettingsKey.hasSeenOnboarding) private var hasSeenOnboarding = false

    @State private var nameText = ""
    @State private var validationMessage: String?

    var body: some View {
        AppScreen {
            VStack(spacing: 0) {
                Spacer(minLength: 48)

                VStack(spacing: 18) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppColors.softTealBackground)
                            .frame(width: 64, height: 64)

                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(AppColors.darkTeal)
                    }

                    Text("Welcome to SlipDee")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)
                        .multilineTextAlignment(.center)

                    Text("What should we call you?")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)
                }
                .padding(.horizontal, AppSpacing.page)

                Spacer(minLength: 32)

                AppCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your name")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.secondaryText)

                        TextField("Your name", text: $nameText)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .foregroundStyle(AppColors.primaryText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .background(AppColors.elevatedCardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous))

                        if let validationMessage {
                            Text(validationMessage)
                                .font(.caption)
                                .foregroundStyle(AppColors.expense)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.page)

                Spacer()

                Button("Continue") {
                    saveName()
                }
                .buttonStyle(PrimaryFintechButtonStyle())
                .padding(.horizontal, AppSpacing.page)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            nameText = userDisplayName
        }
    }

    private func saveName() {
        let trimmedName = sanitizedName

        guard !trimmedName.isEmpty else {
            validationMessage = "Please enter your name to continue."
            return
        }

        guard trimmedName.count <= 30 else {
            validationMessage = "Please keep your name under 30 characters."
            return
        }

        userDisplayName = trimmedName
        hasCompletedNameSetup = true
        hasCompletedSecuritySetup = false
        hasSeenOnboarding = true
        validationMessage = nil
    }

    private var sanitizedName: String {
        nameText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

import SwiftUI

struct FirstLaunchSecuritySetupView: View {
    @AppStorage(AppSettingsKey.hasCompletedSecuritySetup) private var hasCompletedSecuritySetup = false
    @AppStorage(AppSettingsKey.isAppPasscodeEnabled) private var isAppPasscodeEnabled = false
    @AppStorage(AppSettingsKey.appPasscodeHash) private var appPasscodeHash = ""
    @AppStorage(AppSettingsKey.isFaceIDLockEnabled) private var isFaceIDLockEnabled = false
    @AppStorage(AppSettingsKey.lockTimeout) private var lockTimeoutRawValue = AppLockTimeout.immediate.rawValue
    @AppStorage(AppSettingsKey.hasSeenOnboarding) private var hasSeenOnboarding = false

    @State private var isPasscodeEnabled = false
    @State private var passcode = ""
    @State private var confirmPasscode = ""
    @State private var validationMessage: String?

    var body: some View {
        AppScreen {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 40)

                    VStack(spacing: 18) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppColors.softTealBackground)
                                .frame(width: 68, height: 68)

                            Image(systemName: "lock.shield")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(AppColors.darkTeal)
                        }

                        Text("Secure your SlipDee")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColors.primaryText)
                            .multilineTextAlignment(.center)

                        Text("Protect your financial records with a simple 4-digit passcode.")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, AppSpacing.page)

                    Spacer(minLength: 28)

                    AppCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Toggle(isOn: $isPasscodeEnabled) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Enable Passcode Lock")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppColors.primaryText)

                                    Text("Require a passcode before entering SlipDee.")
                                        .font(.caption)
                                        .foregroundStyle(AppColors.secondaryText)
                                }
                            }
                            .tint(AppColors.primaryTeal)

                            if isPasscodeEnabled {
                                VStack(alignment: .leading, spacing: 14) {
                                    secureInputField(
                                        title: "Enter 4-digit passcode",
                                        text: $passcode
                                    )
                                    secureInputField(
                                        title: "Confirm passcode",
                                        text: $confirmPasscode
                                    )

                                    Text("Use 4 digits only.")
                                        .font(.caption)
                                        .foregroundStyle(AppColors.mutedText)
                                }
                            }

                            if let validationMessage {
                                Text(validationMessage)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppColors.expense)
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.page)

                    Spacer(minLength: 18)

                    AppCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Security note")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppColors.primaryText)

                            Text("Your passcode is stored as a secure hash on this device. SlipDee never asks for your bank password.")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondaryText)
                        }
                    }
                    .padding(.horizontal, AppSpacing.page)

                    Spacer(minLength: 28)

                    Button("Continue") {
                        continueIntoApp()
                    }
                    .buttonStyle(PrimaryFintechButtonStyle())
                    .padding(.horizontal, AppSpacing.page)
                    .padding(.bottom, 30)
                }
            }
        }
        .onChange(of: passcode) { _, newValue in
            passcode = sanitizedPasscode(from: newValue)
        }
        .onChange(of: confirmPasscode) { _, newValue in
            confirmPasscode = sanitizedPasscode(from: newValue)
        }
    }

    private func secureInputField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.secondaryText)

            SecureField(title, text: text)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .foregroundStyle(AppColors.primaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(AppColors.elevatedCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous)
                        .stroke(AppColors.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous))
        }
    }

    private func continueIntoApp() {
        validationMessage = nil
        hasSeenOnboarding = true

        guard isPasscodeEnabled else {
            isAppPasscodeEnabled = false
            appPasscodeHash = ""
            isFaceIDLockEnabled = false
            lockTimeoutRawValue = AppLockTimeout.immediate.rawValue
            hasCompletedSecuritySetup = true
            return
        }

        guard AppPasscodeService.isValidFourDigitPasscode(passcode) else {
            validationMessage = "Please enter a 4-digit passcode."
            return
        }

        guard passcode.allSatisfy(\.isNumber), confirmPasscode.allSatisfy(\.isNumber) else {
            validationMessage = "Passcode must contain numbers only."
            return
        }

        guard passcode == confirmPasscode else {
            validationMessage = "Passcodes do not match."
            return
        }

        isAppPasscodeEnabled = true
        appPasscodeHash = AppPasscodeService.hash(passcode)
        isFaceIDLockEnabled = false
        lockTimeoutRawValue = AppLockTimeout.immediate.rawValue
        hasCompletedSecuritySetup = true
    }

    private func sanitizedPasscode(from value: String) -> String {
        String(value.filter(\.isNumber).prefix(4))
    }
}

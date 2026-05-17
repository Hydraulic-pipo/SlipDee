import SwiftUI

struct AppLockView: View {
    @ObservedObject var lockManager: AppLockManager

    @State private var passcode = ""
    @State private var validationMessage: String?

    var body: some View {
        AppScreen {
            VStack(spacing: 0) {
                Spacer(minLength: 48)

                VStack(spacing: 18) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppColors.softTealBackground)
                            .frame(width: 68, height: 68)

                        Image(systemName: "lock.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(AppColors.darkTeal)
                    }

                    Text("Welcome back")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)

                    Text("Enter your 4-digit passcode to unlock SlipDee.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, AppSpacing.page)

                Spacer(minLength: 28)

                AppCard {
                    VStack(alignment: .leading, spacing: 16) {
                        if lockManager.requiresPasscode {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Passcode")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppColors.secondaryText)

                                SecureField("4-digit passcode", text: $passcode)
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

                        if let validationMessage {
                            Text(validationMessage)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppColors.expense)
                        } else if let errorMessage = lockManager.errorMessage {
                            Text(errorMessage)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppColors.expense)
                        }

                        VStack(spacing: 12) {
                            if lockManager.requiresPasscode {
                                Button("Unlock") {
                                    unlockWithPasscode()
                                }
                                .buttonStyle(PrimaryFintechButtonStyle())
                                .disabled(passcode.count != 4)
                                .opacity(passcode.count == 4 ? 1 : 0.55)
                            }

                            if lockManager.canUseBiometricUnlock {
                                Button(lockManager.isAuthenticating ? "Checking..." : "Use Face ID / Touch ID") {
                                    Task {
                                        await lockManager.unlockWithBiometrics()
                                    }
                                }
                                .buttonStyle(SecondaryFintechButtonStyle())
                                .disabled(lockManager.isAuthenticating)
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.page)

                Spacer()
            }
        }
        .onChange(of: passcode) { _, newValue in
            passcode = String(newValue.filter(\.isNumber).prefix(4))
            validationMessage = nil
        }
    }

    private func unlockWithPasscode() {
        guard AppPasscodeService.isValidFourDigitPasscode(passcode) else {
            validationMessage = "Please enter a 4-digit passcode."
            return
        }

        let didUnlock = lockManager.unlockWithPasscode(passcode)
        if !didUnlock {
            validationMessage = "Incorrect passcode. Please try again."
            passcode = ""
        }
    }
}

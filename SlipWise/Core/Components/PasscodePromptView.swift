import SwiftUI

struct PasscodePromptView: View {
    let title: String
    let subtitle: String
    let confirmTitle: String
    let failureMessage: String
    let onCancel: () -> Void
    let onConfirm: (String) -> Bool

    @State private var passcode = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            AppScreen {
                VStack(spacing: AppSpacing.section) {
                    Spacer()

                    AppCard {
                        VStack(alignment: .leading, spacing: 18) {
                            Text(title)
                                .font(.title3.bold())
                                .foregroundStyle(AppColors.primaryText)

                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondaryText)

                            SecureField("4-digit passcode", text: $passcode)
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .background(AppColors.background)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous)
                                        .stroke(AppColors.border, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous))

                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundStyle(AppColors.expense)
                            }

                            HStack(spacing: 12) {
                                Button("Cancel", action: onCancel)
                                    .buttonStyle(SecondaryFintechButtonStyle())

                                Button(confirmTitle) {
                                    guard onConfirm(passcode) else {
                                        errorMessage = failureMessage
                                        passcode = ""
                                        return
                                    }
                                }
                                .buttonStyle(PrimaryFintechButtonStyle())
                                .disabled(passcode.isEmpty)
                                .opacity(passcode.isEmpty ? 0.55 : 1)
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.page)

                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

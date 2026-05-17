import SwiftUI

struct EditDisplayNameView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("userDisplayName") private var userDisplayName = ""
    @AppStorage("hasCompletedNameSetup") private var hasCompletedNameSetup = false

    @State private var nameText = ""
    @State private var validationMessage: String?

    var body: some View {
        AppScreen {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    Text("Display Name")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)

                    Text("Choose the name SlipDee should use in your greeting.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)

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

                    Button("Save") {
                        saveName()
                    }
                    .buttonStyle(PrimaryFintechButtonStyle())
                }
                .padding(.horizontal, AppSpacing.page)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Display Name")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundStyle(AppColors.primaryText)
            }
        }
        .onAppear {
            nameText = userDisplayName
        }
    }

    private func saveName() {
        let trimmedName = nameText.trimmingCharacters(in: .whitespacesAndNewlines)

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
        validationMessage = nil
        dismiss()
    }
}

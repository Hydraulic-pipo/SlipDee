import SwiftData
import SwiftUI

private enum SensitiveTransactionAction {
    case edit
    case delete

    var reason: String {
        switch self {
        case .edit:
            return "Authenticate to edit this transaction."
        case .delete:
            return "Authenticate to delete this transaction."
        }
    }

    var passcodeSubtitle: String {
        switch self {
        case .edit:
            return "Required to edit this transaction."
        case .delete:
            return "Required to delete this transaction."
        }
    }
}

struct TransactionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [UserSettings]
    @AppStorage(AppSettingsKey.isEditDeleteProtectionEnabled) private var isEditDeleteProtectionEnabled = true
    @AppStorage(AppSettingsKey.isBiometricEditDeleteEnabled) private var isBiometricEditDeleteEnabled = true
    @AppStorage(AppSettingsKey.isHideAmountsEnabled) private var isHideAmountsEnabled = false

    let transaction: TransactionItem

    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingPasscodePrompt = false
    @State private var isAuthenticatingForEdit = false
    @State private var authenticationErrorMessage: String?
    @State private var pendingAction: SensitiveTransactionAction?

    private let authenticationService = AppAuthenticationService()
    private let passcodeService = AppPasscodeService()

    private var settings: UserSettings? {
        settingsList.first
    }

    var body: some View {
        AppScreen {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    amountHeader
                    detailCard

                    if let authenticationErrorMessage {
                        AppCard {
                            Text(authenticationErrorMessage)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.expense)
                        }
                    }

                    actionButtons
                }
                .padding(.horizontal, AppSpacing.page)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            EditTransactionView(transaction: transaction)
        }
        .sheet(isPresented: $showingPasscodePrompt) {
            PasscodePromptView(
                title: "Enter Passcode",
                subtitle: pendingAction?.passcodeSubtitle ?? "Required to continue.",
                confirmTitle: "Confirm",
                failureMessage: "Incorrect passcode. Please try again.",
                onCancel: {
                    showingPasscodePrompt = false
                },
                onConfirm: { passcode in
                    let verified = passcodeService.verifyPasscode(passcode, settings: settings)
                    if verified {
                        showingPasscodePrompt = false
                        continueAuthenticatedAction()
                    }
                    return verified
                }
            )
        }
        .alert("Delete Transaction?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteTransaction()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private var amountHeader: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(transaction.type.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.secondaryText)

                Text(displayAmount)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(amountColor)
            }
        }
    }

    private var detailCard: some View {
        AppCard {
            VStack(spacing: 0) {
                detailRow(icon: "arrow.left.arrow.right", label: "Type", value: transaction.type.title)
                divider
                detailRow(icon: "calendar", label: "Date", value: DateParsers.shortDateTime.string(from: transaction.transactionDate))
                divider
                detailRow(icon: "square.grid.2x2", label: "Category", value: transaction.categoryName)
                divider
                detailRow(icon: "creditcard", label: "Payment Method", value: transaction.paymentMethod.title)
                divider
                detailRow(icon: "person", label: "Merchant / Receiver", value: transaction.displayName)
                divider
                detailRow(icon: "building.columns", label: "Bank", value: transaction.bankName.isEmpty ? "Not provided" : transaction.bankName)
                divider
                detailRow(icon: "number", label: "Reference No.", value: transaction.transactionReference.isEmpty ? "Not provided" : transaction.transactionReference)
                divider
                detailRow(icon: "note.text", label: "Note", value: transaction.note.isEmpty ? "Not provided" : transaction.note)
                divider
                detailRow(icon: "clock", label: "Created", value: DateParsers.shortDateTime.string(from: transaction.createdAt))
                divider
                detailRow(icon: "pencil", label: "Updated", value: DateParsers.shortDateTime.string(from: transaction.updatedAt))
                divider
                detailRow(icon: "doc.text.image", label: "Slip Source", value: slipSourceText)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button("Edit Transaction") {
                Task {
                    await handleSensitiveAction(.edit)
                }
            }
            .buttonStyle(PrimaryFintechButtonStyle())
            .disabled(isAuthenticatingForEdit)
            .opacity(isAuthenticatingForEdit ? 0.72 : 1)

            Button("Delete Transaction") {
                Task {
                    await handleSensitiveAction(.delete)
                }
            }
            .buttonStyle(SecondaryFintechButtonStyle())
        }
    }

    private var divider: some View {
        Divider()
            .overlay(AppColors.border)
            .padding(.leading, 34)
    }

    private var amountColor: Color {
        switch transaction.type {
        case .income:
            return AppColors.income
        case .expense:
            return AppColors.expense
        case .transfer:
            return AppColors.darkTeal
        }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(AppColors.primaryTeal)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.secondaryText)

                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.primaryText)
            }

            Spacer()
        }
        .padding(.vertical, 16)
    }

    private var slipSourceText: String {
        if let sourceImageName = transaction.sourceImageName, !sourceImageName.isEmpty {
            return sourceImageName
        }

        return transaction.isFromSlip ? "Imported slip" : "Manual entry"
    }

    private func handleSensitiveAction(_ action: SensitiveTransactionAction) async {
        await MainActor.run {
            authenticationErrorMessage = nil
            pendingAction = action
            if action == .edit {
                isAuthenticatingForEdit = true
            }
        }

        guard isEditDeleteProtectionEnabled else {
            await MainActor.run {
                if action == .edit {
                    isAuthenticatingForEdit = false
                }
                continueAuthenticatedAction()
            }
            return
        }

        let biometricsEnabled = isBiometricEditDeleteEnabled
        let passcodeAvailable = settings?.isEditDeletePasswordEnabled == true && passcodeService.hasPasscode(settings: settings)

        let result = await authenticationService.authenticateForSensitiveAction(
            reason: action.reason,
            biometricsEnabled: biometricsEnabled,
            passcodeAvailable: passcodeAvailable
        )

        await MainActor.run {
            if action == .edit {
                isAuthenticatingForEdit = false
            }

            switch result {
            case .success:
                continueAuthenticatedAction()
            case .requiresPasscode:
                showingPasscodePrompt = true
            case .cancelled:
                pendingAction = nil
            case .unavailable:
                authenticationErrorMessage = passcodeAvailable
                    ? "Face ID or Touch ID isn't available right now. Enter your passcode to continue."
                    : "Face ID or Touch ID isn't available on this device right now."
            case .failure:
                authenticationErrorMessage = "Authentication failed. Please try again."
            }
        }
    }

    private func continueAuthenticatedAction() {
        guard let pendingAction else { return }

        switch pendingAction {
        case .edit:
            showingEditSheet = true
        case .delete:
            showingDeleteConfirmation = true
        }

        self.pendingAction = nil
    }

    private func deleteTransaction() {
        modelContext.delete(transaction)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            authenticationErrorMessage = "We couldn't delete this transaction. Please try again."
        }
    }

    private var displayAmount: String {
        switch transaction.type {
        case .income:
            return AmountDisplayFormatter.display(amount: transaction.amount, isHidden: isHideAmountsEnabled, showSign: true, isIncome: true)
        case .expense:
            return AmountDisplayFormatter.display(amount: transaction.amount, isHidden: isHideAmountsEnabled, showSign: true, isIncome: false)
        case .transfer:
            return AmountDisplayFormatter.display(amount: transaction.amount, isHidden: isHideAmountsEnabled)
        }
    }
}

import SwiftData
import SwiftUI

private enum SecurityPasscodePromptMode: Identifiable {
    case setup
    case change

    var id: String {
        switch self {
        case .setup:
            return "setup"
        case .change:
            return "change"
        }
    }

    var title: String {
        switch self {
        case .setup:
            return "Set Passcode"
        case .change:
            return "Change Passcode"
        }
    }

    var subtitle: String {
        switch self {
        case .setup:
            return "Create a 4-digit passcode to protect editing and deleting transactions."
        case .change:
            return "Enter a new 4-digit passcode for edit and delete protection."
        }
    }

    var confirmTitle: String {
        switch self {
        case .setup:
            return "Save"
        case .change:
            return "Update"
        }
    }
}

struct EditDeleteSecurityView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [UserSettings]
    @AppStorage(AppSettingsKey.isEditDeleteProtectionEnabled) private var isEditDeleteProtectionEnabled = true
    @AppStorage(AppSettingsKey.isBiometricEditDeleteEnabled) private var isBiometricEditDeleteEnabled = true

    @State private var promptMode: SecurityPasscodePromptMode?
    @State private var helperMessage: String?

    private let authenticationService = AppAuthenticationService()
    private let passcodeService = AppPasscodeService()

    private var settings: UserSettings? {
        settingsList.first
    }

    var body: some View {
        AppScreen {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    Text("Edit & Delete Protection")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)

                    Text("Protect changes to saved transactions with biometrics or an app passcode.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)

                    settingsSection(title: "Protection") {
                        toggleRow(
                            icon: "lock.shield",
                            title: "Require authentication before editing and deleting",
                            subtitle: "When off, changes happen without biometric confirmation",
                            isOn: Binding(get: { isEditDeleteProtectionEnabled }, set: updateEditDeleteProtection)
                        )
                        divider
                        toggleRow(
                            icon: "faceid",
                            title: "Use Face ID / Touch ID",
                            subtitle: "Biometrics are used before passcode fallback",
                            isOn: Binding(get: { isBiometricEditDeleteEnabled }, set: updateBiometricProtection)
                        )
                        divider
                        Button {
                            promptMode = .change
                        } label: {
                            SettingsRowView(
                                icon: "number.square",
                                title: passcodeService.hasPasscode(settings: settings) ? "Change App Passcode" : "Set App Passcode",
                                subtitle: "Minimum 4 digits",
                                trailingText: passcodeService.hasPasscode(settings: settings) ? "Configured" : "Not Set"
                            )
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                    }

                    if let helperMessage {
                        AppCard {
                            Text(helperMessage)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondaryText)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.page)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            ensureSettings()
            syncToStoredSettings()
        }
        .sheet(item: $promptMode) { mode in
            PasscodePromptView(
                title: mode.title,
                subtitle: mode.subtitle,
                confirmTitle: mode.confirmTitle,
                failureMessage: "Passcode must be at least 4 digits.",
                onCancel: {
                    promptMode = nil
                },
                onConfirm: { passcode in
                    guard
                        let settings,
                        passcodeService.isValidPasscode(passcode)
                    else {
                        return false
                    }

                    passcodeService.setPasscode(passcode, settings: settings)
                    applyProtectionState()
                    try? modelContext.save()
                    helperMessage = "Your passcode has been saved."
                    promptMode = nil
                    return true
                }
            )
        }
    }

    private var divider: some View {
        Divider()
            .overlay(AppColors.border)
            .padding(.leading, 48)
    }

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.secondaryText)

            AppCard {
                VStack(spacing: 0) {
                    content()
                }
            }
        }
    }

    private func toggleRow(
        icon: String,
        title: String,
        subtitle: String? = nil,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.darkTeal)
                .frame(width: 34, height: 34)
                .background(AppColors.softMint)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(AppColors.primaryTeal)
        }
        .padding(.vertical, 10)
    }

    private func ensureSettings() {
        guard settings == nil else { return }

        let userSettings = UserSettings(
            isEditProtectionEnabled: isEditDeleteProtectionEnabled,
            isDeleteProtectionEnabled: isEditDeleteProtectionEnabled,
            isBiometricEditDeleteEnabled: isBiometricEditDeleteEnabled
        )
        modelContext.insert(userSettings)
        try? modelContext.save()
    }

    private func syncToStoredSettings() {
        guard let settings else { return }
        isEditDeleteProtectionEnabled = settings.isEditDeleteProtectionEnabled
        isBiometricEditDeleteEnabled = settings.isBiometricEditDeleteEnabled || !passcodeService.hasPasscode(settings: settings)
    }

    private func updateEditDeleteProtection(_ isEnabled: Bool) {
        guard let settings else { return }
        helperMessage = nil

        guard isEnabled else {
            isEditDeleteProtectionEnabled = false
            applyProtectionState()
            try? modelContext.save()
            return
        }

        if authenticationService.canAuthenticateWithBiometrics() || passcodeService.hasPasscode(settings: settings) {
            isEditDeleteProtectionEnabled = true
            applyProtectionState()
            try? modelContext.save()
        } else {
            promptMode = .setup
        }
    }

    private func updateBiometricProtection(_ isEnabled: Bool) {
        guard settings != nil else { return }
        helperMessage = nil

        guard isEnabled else {
            isBiometricEditDeleteEnabled = false
            applyProtectionState()
            try? modelContext.save()
            return
        }

        guard authenticationService.canAuthenticateWithBiometrics() else {
            isBiometricEditDeleteEnabled = false
            helperMessage = "Face ID or Touch ID isn't available on this device. You can still use an app passcode."
            return
        }

        isBiometricEditDeleteEnabled = true
        applyProtectionState()
        try? modelContext.save()
    }

    private func applyProtectionState() {
        guard let settings else { return }

        settings.isEditProtectionEnabled = isEditDeleteProtectionEnabled
        settings.isDeleteProtectionEnabled = isEditDeleteProtectionEnabled
        settings.isBiometricEditDeleteEnabled = isBiometricEditDeleteEnabled
        settings.isEditDeletePasswordEnabled = passcodeService.hasPasscode(settings: settings)
        settings.touch()
    }
}

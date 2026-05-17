import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettingsKey.appearanceMode) private var appearanceModeRawValue = AppAppearanceMode.system.rawValue
    @AppStorage(AppSettingsKey.userDisplayName) private var userDisplayName = ""
    @AppStorage(AppSettingsKey.isFaceIDLockEnabled) private var isFaceIDLockEnabled = false
    @AppStorage(AppSettingsKey.isAppPasscodeEnabled) private var isAppPasscodeEnabled = false
    @AppStorage(AppSettingsKey.appPasscodeHash) private var appPasscodeHash = ""
    @AppStorage(AppSettingsKey.isEditDeleteProtectionEnabled) private var isEditDeleteProtectionEnabled = true
    @AppStorage(AppSettingsKey.lockTimeout) private var lockTimeoutRawValue = AppLockTimeout.immediate.rawValue
    @AppStorage(AppSettingsKey.isHideAmountsEnabled) private var isHideAmountsEnabled = false
    @AppStorage(AppSettingsKey.isScreenshotProtectionEnabled) private var isScreenshotProtectionEnabled = false
    @AppStorage(AppSettingsKey.isOnDeviceProcessingEnabled) private var isOnDeviceProcessingEnabled = true
    @AppStorage(AppSettingsKey.hasCompletedNameSetup) private var hasCompletedNameSetup = false
    @AppStorage(AppSettingsKey.hasCompletedSecuritySetup) private var hasCompletedSecuritySetup = false
    @AppStorage(AppSettingsKey.hasSeenOnboarding) private var hasSeenOnboarding = false

    @State private var helperMessage: String?

    private let authenticationService = AppAuthenticationService()

    var body: some View {
        AppScreen {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    Text("Settings")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)

                    profileSection
                    appearanceSection
                    privacySection
                    bankSourcesSection
                    dataSection
                    aboutSection

                    if let helperMessage {
                        AppCard {
                            Text(helperMessage)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondaryText)
                        }
                    }

                    #if DEBUG
                    debugSection
                    #endif
                }
                .padding(.horizontal, AppSpacing.page)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            if !isOnDeviceProcessingEnabled {
                isOnDeviceProcessingEnabled = true
            }
        }
    }

    private var profileSection: some View {
        settingsSection(title: "Profile") {
            NavigationLink {
                EditDisplayNameView()
            } label: {
                SettingsRowView(
                    icon: "person.crop.circle",
                    title: "Display Name",
                    subtitle: "Change the name shown in your greeting",
                    trailingText: trimmedDisplayName.isEmpty ? "Not Set" : trimmedDisplayName
                )
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
    }

    private var appearanceSection: some View {
        settingsSection(title: "Appearance") {
            NavigationLink {
                AppearanceSettingsView()
            } label: {
                SettingsRowView(
                    icon: "circle.lefthalf.filled",
                    title: "Appearance",
                    subtitle: "Choose System, Light, or Dark mode",
                    trailingText: selectedAppearanceMode.title
                )
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
    }

    private var privacySection: some View {
        settingsSection(title: "Privacy & Security") {
            toggleRow(
                icon: "faceid",
                title: "Face ID Lock",
                subtitle: "Require authentication when you return to the app",
                isOn: Binding(get: { isFaceIDLockEnabled }, set: updateFaceIDLock)
            )
            divider
            NavigationLink {
                EditDeleteSecurityView()
            } label: {
                SettingsRowView(
                    icon: "lock.shield",
                    title: "Edit & Delete Protection",
                    subtitle: "Require authentication before sensitive actions",
                    trailingText: isEditDeleteProtectionEnabled ? "On" : "Off"
                )
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            divider
            NavigationLink {
                LockTimeoutSettingsView()
            } label: {
                SettingsRowView(
                    icon: "timer",
                    title: "Lock Timeout",
                    trailingText: selectedLockTimeout.shortTitle
                )
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            divider
            SettingsRowView(
                icon: "number.square",
                title: "App Passcode",
                subtitle: "Configured during first launch",
                trailingText: hasAppPasscodeConfigured ? "On" : "Off",
                showsChevron: false
            )
            .padding(.vertical, 10)
            divider
            toggleRow(
                icon: "eye.slash",
                title: "Hide Amounts",
                subtitle: "Mask balances and spending across the app",
                isOn: $isHideAmountsEnabled
            )
            divider
            toggleRow(
                icon: "shield",
                title: "Screenshot Protection",
                subtitle: "Hide sensitive data in the app switcher",
                isOn: $isScreenshotProtectionEnabled
            )
            divider
            toggleRow(
                icon: "lock.doc",
                title: "Data Processing",
                subtitle: "SlipDee currently processes data on this device only.",
                isOn: $isOnDeviceProcessingEnabled,
                isDisabled: true
            )
        }
    }

    private var bankSourcesSection: some View {
        settingsSection(title: "Bank Sources") {
            NavigationLink {
                SupportedBanksView()
            } label: {
                SettingsRowView(icon: "building.columns", title: "Supported Banks")
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            divider
            NavigationLink {
                ManageBankLogosView()
            } label: {
                SettingsRowView(
                    icon: "photo",
                    title: "Manage Bank Logos",
                    trailingText: "Coming Soon"
                )
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
    }

    private var dataSection: some View {
        settingsSection(title: "Data & Export") {
            NavigationLink {
                DataExportView()
            } label: {
                SettingsRowView(
                    icon: "square.and.arrow.up",
                    title: "Data & Export",
                    subtitle: "CSV export"
                )
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            divider
            SettingsRowView(
                icon: "icloud",
                title: "Backup to iCloud",
                subtitle: "iCloud backup has not been enabled yet.",
                trailingText: "Coming Soon",
                showsChevron: false
            )
            .padding(.vertical, 10)
        }
    }

    private var aboutSection: some View {
        settingsSection(title: "About") {
            SettingsRowView(icon: "info.circle", title: "Version", trailingText: "1.0", showsChevron: false)
                .padding(.vertical, 10)
            divider
            SettingsRowView(icon: "doc.text", title: "Terms of Service", trailingText: "Coming Soon", showsChevron: false)
                .padding(.vertical, 10)
            divider
            SettingsRowView(icon: "hand.raised", title: "Privacy Policy", trailingText: "Coming Soon", showsChevron: false)
                .padding(.vertical, 10)
        }
    }

    private var divider: some View {
        Divider()
            .overlay(AppColors.border)
            .padding(.leading, 48)
    }

    #if DEBUG
    private var debugSection: some View {
        settingsSection(title: "Developer") {
            Button {
                resetAppForNewUser()
            } label: {
                SettingsRowView(
                    icon: "arrow.counterclockwise",
                    title: "Reset App for New User",
                    subtitle: "Clears onboarding and security setup",
                    showsChevron: false
                )
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
    }
    #endif

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
        isOn: Binding<Bool>,
        isDisabled: Bool = false
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
                .disabled(isDisabled)
        }
        .padding(.vertical, 10)
        .opacity(isDisabled ? 0.72 : 1)
    }

    private func updateFaceIDLock(_ isEnabled: Bool) {
        helperMessage = nil

        guard isEnabled else {
            isFaceIDLockEnabled = false
            return
        }

        guard authenticationService.canAuthenticateWithBiometrics() else {
            isFaceIDLockEnabled = false
            helperMessage = "Face ID or Touch ID isn't available on this device yet, so app lock can't be enabled."
            return
        }

        isFaceIDLockEnabled = true
    }

    private var selectedAppearanceMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceModeRawValue) ?? .system
    }

    private var selectedLockTimeout: AppLockTimeout {
        AppLockTimeout(rawValue: lockTimeoutRawValue) ?? .immediate
    }

    private var trimmedDisplayName: String {
        userDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasAppPasscodeConfigured: Bool {
        isAppPasscodeEnabled && !appPasscodeHash.isEmpty
    }

    private func resetAppForNewUser() {
        userDisplayName = ""
        hasCompletedNameSetup = false
        hasCompletedSecuritySetup = false
        hasSeenOnboarding = false
        isAppPasscodeEnabled = false
        appPasscodeHash = ""
        isFaceIDLockEnabled = false
        lockTimeoutRawValue = AppLockTimeout.immediate.rawValue
        helperMessage = "The app has been reset for first-launch testing."
    }
}

import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [UserSettings]
    @AppStorage("appearanceMode") private var appearanceModeRawValue = AppAppearanceMode.system.rawValue

    @State private var hideAmounts = false
    @State private var screenshotProtection = false
    @State private var processingOnDevice = true

    private var settings: UserSettings? {
        settingsList.first
    }

    var body: some View {
        AppScreen {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    Text("Settings")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)

                    appearanceSection
                    privacySection
                    bankSourcesSection
                    dataSection
                    aboutSection
                }
                .padding(.horizontal, AppSpacing.page)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .onAppear(perform: ensureSettings)
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
                subtitle: "Unlock the app quickly",
                isOn: Binding(
                    get: { settings?.isBiometricUnlockEnabled ?? false },
                    set: updateBiometricUnlock
                )
            )
            divider
            NavigationLink {
                EditDeleteSecurityView()
            } label: {
                SettingsRowView(
                    icon: "lock.shield",
                    title: "Edit & Delete Protection",
                    subtitle: "Require authentication before sensitive actions",
                    trailingText: (settings?.isEditDeleteProtectionEnabled ?? false) ? "On" : "Off"
                )
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            divider
            SettingsRowView(icon: "timer", title: "Lock Timeout", trailingText: settings?.appLockTimeout.title ?? "Immediately")
                .padding(.vertical, 10)
            divider
            toggleRow(icon: "eye.slash", title: "Hide Amounts", isOn: $hideAmounts)
            divider
            toggleRow(icon: "shield", title: "Screenshot Protection", isOn: $screenshotProtection)
            divider
            toggleRow(icon: "lock.doc", title: "Data Processing", subtitle: "On-device only", isOn: $processingOnDevice)
        }
    }

    private var bankSourcesSection: some View {
        settingsSection(title: "Bank Sources") {
            SettingsRowView(icon: "building.columns", title: "Supported Banks")
                .padding(.vertical, 10)
            divider
            SettingsRowView(icon: "photo", title: "Manage Bank Logos")
                .padding(.vertical, 10)
        }
    }

    private var dataSection: some View {
        settingsSection(title: "Data & Export") {
            SettingsRowView(icon: "square.and.arrow.up", title: "Export Data")
                .padding(.vertical, 10)
            divider
            SettingsRowView(icon: "icloud", title: "Backup to iCloud")
                .padding(.vertical, 10)
        }
    }

    private var aboutSection: some View {
        settingsSection(title: "About") {
            SettingsRowView(icon: "info.circle", title: "Version", trailingText: "1.0", showsChevron: false)
                .padding(.vertical, 10)
            divider
            SettingsRowView(icon: "doc.text", title: "Terms of Service")
                .padding(.vertical, 10)
            divider
            SettingsRowView(icon: "hand.raised", title: "Privacy Policy")
                .padding(.vertical, 10)
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

        let userSettings = UserSettings()
        modelContext.insert(userSettings)
        try? modelContext.save()
    }

    private func updateBiometricUnlock(_ isEnabled: Bool) {
        guard let settings else { return }
        settings.isBiometricUnlockEnabled = isEnabled
        settings.touch()
        try? modelContext.save()
    }

    private var selectedAppearanceMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceModeRawValue) ?? .system
    }
}

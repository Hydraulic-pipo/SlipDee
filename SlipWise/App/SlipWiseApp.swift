import SwiftData
import SwiftUI

@main
struct SlipWiseApp: App {
    private enum LaunchState {
        case ready(ModelContainer)
        case databaseUnavailable
    }

    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppSettingsKey.hasSeenOnboarding) private var hasSeenOnboarding = false
    @AppStorage(AppSettingsKey.appearanceMode) private var appearanceModeRawValue = AppAppearanceMode.system.rawValue
    @AppStorage(AppSettingsKey.userDisplayName) private var userDisplayName = ""
    @AppStorage(AppSettingsKey.hasCompletedNameSetup) private var hasCompletedNameSetup = false
    @AppStorage(AppSettingsKey.hasCompletedSecuritySetup) private var hasCompletedSecuritySetup = false
    @AppStorage(AppSettingsKey.isScreenshotProtectionEnabled) private var isScreenshotProtectionEnabled = false

    @StateObject private var appLockManager = AppLockManager()

    private let launchState: LaunchState = {
        let schema = Schema([
            TransactionItem.self,
            TransactionCategory.self,
            RecurringIncome.self,
            RecurringIncomeOccurrence.self,
            SlipRecord.self,
            Budget.self,
            MerchantRule.self,
            UserSettings.self
        ])

        let storeURL = Self.defaultStoreURL()

        do {
            return .ready(try Self.makeContainer(schema: schema, storeURL: storeURL))
        } catch {
            #if DEBUG
            print("Failed to create model container at \(storeURL.path): \(error.localizedDescription)")
            #endif
            // TODO: Add an explicit SwiftData migration plan before shipping schema changes.
            // Never delete the existing store automatically on launch failure.
            return .databaseUnavailable
        }
    }()

    var body: some Scene {
        WindowGroup {
            switch launchState {
            case let .ready(modelContainer):
                ZStack {
                    Group {
                        if shouldShowNameSetup {
                            UserNameSetupView()
                        } else if shouldShowSecuritySetup {
                            FirstLaunchSecuritySetupView()
                        } else if appLockManager.isLocked {
                            AppLockView(lockManager: appLockManager)
                        } else if hasSeenOnboarding {
                            MainTabView()
                        } else {
                            OnboardingView {
                                hasSeenOnboarding = true
                            }
                        }
                    }

                    if isScreenshotProtectionEnabled, scenePhase != .active {
                        PrivacyOverlayView(
                            title: "SlipDee",
                            message: "Your financial data is protected."
                        )
                    }
                }
                .preferredColorScheme(selectedAppearanceMode.colorScheme)
                .task {
                    appLockManager.prepareForLaunch()
                    // Seed small fictional samples so the charts and dashboard are useful on first launch.
                    await DemoDataSeeder.seedIfNeeded(container: modelContainer)
                    await appLockManager.handleScenePhaseChanged(.active)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    Task {
                        await appLockManager.handleScenePhaseChanged(newPhase)
                    }
                }
                .modelContainer(modelContainer)
            case .databaseUnavailable:
                DatabaseErrorView()
            }
        }
    }

    private var selectedAppearanceMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceModeRawValue) ?? .system
    }

    private var shouldShowNameSetup: Bool {
        let trimmedName = userDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !hasCompletedNameSetup || trimmedName.isEmpty
    }

    private var shouldShowSecuritySetup: Bool {
        hasCompletedNameSetup && !shouldShowNameSetup && !hasCompletedSecuritySetup
    }
}

private extension SlipWiseApp {
    static func makeContainer(schema: Schema, storeURL: URL) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func defaultStoreURL() -> URL {
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL.documentsDirectory
        let directoryURL = appSupportURL.appendingPathComponent("SlipWise", isDirectory: true)

        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        return directoryURL.appendingPathComponent("SlipWise.store")
    }
}

private struct DatabaseErrorView: View {
    var body: some View {
        AppScreen {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    Spacer(minLength: 40)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("SlipDee")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppColors.secondaryText)

                        Text("Unable to open local data")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColors.primaryText)

                        Text("Your existing data was preserved. SlipDee did not reset or replace your local database automatically.")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondaryText)
                    }

                    AppCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What you can try")
                                .font(.headline)
                                .foregroundStyle(AppColors.primaryText)

                            Text("1. Close and reopen the app.")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondaryText)

                            Text("2. Make sure your device has available storage and try again.")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondaryText)

                            Text("3. If the problem continues, contact support and mention that SlipDee could not open local data.")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondaryText)
                        }
                    }

                    AppCard {
                        Text("SlipDee will not create a new empty database over your existing records without an explicit reset action.")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondaryText)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, AppSpacing.page)
                .padding(.bottom, 32)
            }
        }
    }
}

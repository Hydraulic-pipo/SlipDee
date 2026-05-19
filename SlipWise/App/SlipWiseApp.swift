import SwiftData
import SwiftUI

@main
struct SlipWiseApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppSettingsKey.hasSeenOnboarding) private var hasSeenOnboarding = false
    @AppStorage(AppSettingsKey.appearanceMode) private var appearanceModeRawValue = AppAppearanceMode.system.rawValue
    @AppStorage(AppSettingsKey.userDisplayName) private var userDisplayName = ""
    @AppStorage(AppSettingsKey.hasCompletedNameSetup) private var hasCompletedNameSetup = false
    @AppStorage(AppSettingsKey.hasCompletedSecuritySetup) private var hasCompletedSecuritySetup = false
    @AppStorage(AppSettingsKey.isScreenshotProtectionEnabled) private var isScreenshotProtectionEnabled = false

    @StateObject private var appLockManager = AppLockManager()

    private let sharedModelContainer: ModelContainer = {
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
            return try Self.makeContainer(schema: schema, storeURL: storeURL)
        } catch {
            // The baseline app used a different TransactionItem schema, so older local stores
            // can fail to migrate during early development. Resetting the local store lets the
            // app recover cleanly while the new data layer settles.
            Self.removeStoreFiles(at: storeURL)

            do {
                return try Self.makeContainer(schema: schema, storeURL: storeURL)
            } catch {
                fatalError("Failed to create model container: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
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
                await DemoDataSeeder.seedIfNeeded(container: sharedModelContainer)
                await appLockManager.handleScenePhaseChanged(.active)
            }
            .onChange(of: scenePhase) { _, newPhase in
                Task {
                    await appLockManager.handleScenePhaseChanged(newPhase)
                }
            }
        }
        .modelContainer(sharedModelContainer)
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

    static func removeStoreFiles(at storeURL: URL) {
        let fileManager = FileManager.default
        let urlsToRemove = [
            storeURL,
            storeURL.appendingPathExtension("shm"),
            storeURL.appendingPathExtension("wal")
        ]

        for url in urlsToRemove where fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: url)
        }
    }
}

import SwiftData
import SwiftUI

@main
struct SlipWiseApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("appearanceMode") private var appearanceModeRawValue = AppAppearanceMode.system.rawValue

    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TransactionItem.self,
            TransactionCategory.self,
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
            Group {
                if hasSeenOnboarding {
                    MainTabView()
                } else {
                    OnboardingView {
                        hasSeenOnboarding = true
                    }
                }
            }
            .preferredColorScheme(selectedAppearanceMode.colorScheme)
            .task {
                // Seed small fictional samples so the charts and dashboard are useful on first launch.
                await DemoDataSeeder.seedIfNeeded(container: sharedModelContainer)
            }
        }
        .modelContainer(sharedModelContainer)
    }

    private var selectedAppearanceMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceModeRawValue) ?? .system
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

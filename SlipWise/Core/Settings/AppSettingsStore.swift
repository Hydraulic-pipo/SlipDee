import Foundation

enum AppSettingsKey {
    static let appearanceMode = "appearanceMode"
    static let isFaceIDLockEnabled = "isFaceIDLockEnabled"
    static let isEditDeleteProtectionEnabled = "isEditDeleteProtectionEnabled"
    static let isBiometricEditDeleteEnabled = "isBiometricEditDeleteEnabled"
    static let lockTimeout = "lockTimeout"
    static let isHideAmountsEnabled = "isHideAmountsEnabled"
    static let isScreenshotProtectionEnabled = "isScreenshotProtectionEnabled"
    static let isOnDeviceProcessingEnabled = "isOnDeviceProcessingEnabled"
    static let userDisplayName = "userDisplayName"
    static let hasCompletedNameSetup = "hasCompletedNameSetup"
    static let hasSeenOnboarding = "hasSeenOnboarding"
}

@MainActor
final class AppSettingsStore: ObservableObject {
    static let shared = AppSettingsStore()

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var appearanceMode: AppAppearanceMode {
        get {
            AppAppearanceMode(rawValue: defaults.string(forKey: AppSettingsKey.appearanceMode) ?? AppAppearanceMode.system.rawValue) ?? .system
        }
        set {
            defaults.set(newValue.rawValue, forKey: AppSettingsKey.appearanceMode)
        }
    }

    var isFaceIDLockEnabled: Bool {
        get { defaults.bool(forKey: AppSettingsKey.isFaceIDLockEnabled) }
        set { defaults.set(newValue, forKey: AppSettingsKey.isFaceIDLockEnabled) }
    }

    var isEditDeleteProtectionEnabled: Bool {
        get {
            if defaults.object(forKey: AppSettingsKey.isEditDeleteProtectionEnabled) == nil {
                return true
            }
            return defaults.bool(forKey: AppSettingsKey.isEditDeleteProtectionEnabled)
        }
        set { defaults.set(newValue, forKey: AppSettingsKey.isEditDeleteProtectionEnabled) }
    }

    var isBiometricEditDeleteEnabled: Bool {
        get {
            if defaults.object(forKey: AppSettingsKey.isBiometricEditDeleteEnabled) == nil {
                return true
            }
            return defaults.bool(forKey: AppSettingsKey.isBiometricEditDeleteEnabled)
        }
        set { defaults.set(newValue, forKey: AppSettingsKey.isBiometricEditDeleteEnabled) }
    }

    var lockTimeout: AppLockTimeout {
        get {
            AppLockTimeout(rawValue: defaults.string(forKey: AppSettingsKey.lockTimeout) ?? AppLockTimeout.immediate.rawValue) ?? .immediate
        }
        set {
            defaults.set(newValue.rawValue, forKey: AppSettingsKey.lockTimeout)
        }
    }

    var isHideAmountsEnabled: Bool {
        get { defaults.bool(forKey: AppSettingsKey.isHideAmountsEnabled) }
        set { defaults.set(newValue, forKey: AppSettingsKey.isHideAmountsEnabled) }
    }

    var isScreenshotProtectionEnabled: Bool {
        get { defaults.bool(forKey: AppSettingsKey.isScreenshotProtectionEnabled) }
        set { defaults.set(newValue, forKey: AppSettingsKey.isScreenshotProtectionEnabled) }
    }

    var isOnDeviceProcessingEnabled: Bool {
        get {
            if defaults.object(forKey: AppSettingsKey.isOnDeviceProcessingEnabled) == nil {
                return true
            }
            return defaults.bool(forKey: AppSettingsKey.isOnDeviceProcessingEnabled)
        }
        set { defaults.set(newValue, forKey: AppSettingsKey.isOnDeviceProcessingEnabled) }
    }
}

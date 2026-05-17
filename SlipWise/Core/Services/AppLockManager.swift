import SwiftUI

@MainActor
final class AppLockManager: ObservableObject {
    @Published private(set) var isLocked = false
    @Published private(set) var isAuthenticating = false
    @Published var errorMessage: String?

    private let authenticationService: AppAuthenticationService
    private let settingsStore: AppSettingsStore
    private var hasAuthenticatedThisSession = false
    private var lastBackgroundDate: Date?

    init(
        authenticationService: AppAuthenticationService = AppAuthenticationService(),
        settingsStore: AppSettingsStore? = nil
    ) {
        self.authenticationService = authenticationService
        self.settingsStore = settingsStore ?? AppSettingsStore.shared
        prepareForLaunch()
    }

    func prepareForLaunch() {
        guard isProtectionEnabled else {
            isLocked = false
            hasAuthenticatedThisSession = false
            return
        }

        isLocked = true
    }

    func handleScenePhaseChanged(_ phase: ScenePhase) async {
        switch phase {
        case .background:
            if isProtectionEnabled {
                lastBackgroundDate = .now
            }
        case .active:
            await authenticateIfNeeded()
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    func unlock() async {
        await unlockWithBiometrics()
    }

    func unlockWithBiometrics() async {
        guard canUseBiometricUnlock else {
            errorMessage = "Biometric authentication is not available."
            return
        }

        await authenticate()
    }

    func unlockWithPasscode(_ passcode: String) -> Bool {
        guard requiresPasscode, AppPasscodeService.verify(passcode, hash: settingsStore.appPasscodeHash) else {
            isLocked = true
            errorMessage = "Incorrect passcode. Please try again."
            return false
        }

        isLocked = false
        hasAuthenticatedThisSession = true
        errorMessage = nil
        return true
    }

    private func authenticateIfNeeded() async {
        guard isProtectionEnabled else {
            isLocked = false
            errorMessage = nil
            hasAuthenticatedThisSession = false
            return
        }

        guard shouldLockNow else { return }
        isLocked = true

        guard canUseBiometricUnlock else {
            errorMessage = nil
            return
        }

        await authenticate()
    }

    private var shouldLockNow: Bool {
        guard !isAuthenticating else { return false }

        if !hasAuthenticatedThisSession {
            return true
        }

        guard let timeout = settingsStore.lockTimeout.timeInterval else {
            return false
        }

        if timeout == 0 {
            return true
        }

        guard let lastBackgroundDate else {
            return false
        }

        return Date().timeIntervalSince(lastBackgroundDate) >= timeout
    }

    private func authenticate() async {
        guard !isAuthenticating else { return }

        isAuthenticating = true
        errorMessage = nil

        let success = await authenticationService.authenticateForAppLock(
            reason: "Unlock SlipDee."
        )

        isAuthenticating = false

        if success {
            isLocked = false
            hasAuthenticatedThisSession = true
            errorMessage = nil
        } else {
            isLocked = true
            errorMessage = "Authentication failed. Please try again."
        }
    }

    var canUseBiometricUnlock: Bool {
        settingsStore.isFaceIDLockEnabled && authenticationService.canAuthenticateWithBiometrics()
    }

    var requiresPasscode: Bool {
        settingsStore.isAppPasscodeEnabled && !settingsStore.appPasscodeHash.isEmpty
    }

    private var isProtectionEnabled: Bool {
        settingsStore.isFaceIDLockEnabled || requiresPasscode
    }
}

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
    private var hasPreparedForLaunch = false

    init(
        authenticationService: AppAuthenticationService = AppAuthenticationService(),
        settingsStore: AppSettingsStore? = nil
    ) {
        self.authenticationService = authenticationService
        self.settingsStore = settingsStore ?? AppSettingsStore.shared
        prepareForLaunch()
    }

    func prepareForLaunch() {
        guard !hasPreparedForLaunch else { return }
        hasPreparedForLaunch = true

        guard isProtectionEnabled else {
            isLocked = false
            hasAuthenticatedThisSession = false
            return
        }

        isLocked = true
    }

    func handleScenePhaseChanged(_ phase: ScenePhase) async {
        if await MainActor.run(body: { AppAuthenticationService.isSystemAuthenticationInProgress }) {
            return
        }

        switch phase {
        case .background:
            if isProtectionEnabled {
                lastBackgroundDate = .now
                hasPreparedForLaunch = true
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
            lastBackgroundDate = nil
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
        guard !AppAuthenticationService.isSystemAuthenticationInProgress else { return false }

        if !hasAuthenticatedThisSession {
            return true
        }

        guard let lastBackgroundDate else {
            return false
        }

        guard let timeout = settingsStore.lockTimeout.timeInterval else {
            return false
        }

        if timeout == 0 {
            return true
        }

        return Date().timeIntervalSince(lastBackgroundDate) >= timeout
    }

    private func authenticate() async {
        guard !isAuthenticating else { return }

        isAuthenticating = true
        errorMessage = nil

        let result = await authenticationService.authenticateForAppLock(
            reason: "Unlock SlipDee.",
            passcodeAvailable: requiresPasscode
        )

        isAuthenticating = false

        switch result {
        case .success:
            isLocked = false
            hasAuthenticatedThisSession = true
            lastBackgroundDate = nil
            errorMessage = nil
        case .requiresPasscode:
            isLocked = true
            errorMessage = requiresPasscode ? nil : "Enter your passcode to continue."
        case .cancelled:
            isLocked = true
            errorMessage = nil
        case .unavailable:
            isLocked = true
            errorMessage = requiresPasscode ? "Face ID or Touch ID isn't available right now. Use your passcode to unlock." : "Face ID or Touch ID isn't available right now."
        case .failure:
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

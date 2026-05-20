import Foundation
import LocalAuthentication

enum AppAuthenticationResult: Equatable {
    case success
    case requiresPasscode
    case cancelled
    case unavailable
    case failure
}

final class AppAuthenticationService {
    @MainActor static var isSystemAuthenticationInProgress = false

    func canAuthenticateWithBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func authenticateForSensitiveAction(
        reason: String,
        biometricsEnabled: Bool,
        passcodeAvailable: Bool
    ) async -> AppAuthenticationResult {
        guard biometricsEnabled else {
            return passcodeAvailable ? .requiresPasscode : .failure
        }

        let context = LAContext()
        context.localizedFallbackTitle = ""
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return unavailableResult(for: error, passcodeAvailable: passcodeAvailable)
        }

        await MainActor.run {
            Self.isSystemAuthenticationInProgress = true
        }
        defer {
            Task { @MainActor in
                Self.isSystemAuthenticationInProgress = false
            }
        }

        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            return success ? .success : (passcodeAvailable ? .requiresPasscode : .failure)
        } catch {
            return result(for: error, passcodeAvailable: passcodeAvailable)
        }
    }

    func authenticateForAppLock(reason: String, passcodeAvailable: Bool) async -> AppAuthenticationResult {
        let context = LAContext()
        context.localizedFallbackTitle = ""
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return unavailableResult(for: error, passcodeAvailable: passcodeAvailable)
        }

        await MainActor.run {
            Self.isSystemAuthenticationInProgress = true
        }
        defer {
            Task { @MainActor in
                Self.isSystemAuthenticationInProgress = false
            }
        }

        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            return success ? .success : .failure
        } catch {
            return result(for: error, passcodeAvailable: passcodeAvailable)
        }
    }

    private func unavailableResult(for error: Error?, passcodeAvailable: Bool) -> AppAuthenticationResult {
        if passcodeAvailable {
            return .requiresPasscode
        }

        guard let laError = error as? LAError else {
            return .unavailable
        }

        switch laError.code {
        case .biometryNotAvailable, .biometryNotEnrolled, .passcodeNotSet, .biometryLockout:
            return .unavailable
        case .userCancel, .appCancel, .systemCancel:
            return .cancelled
        default:
            return .failure
        }
    }

    private func result(for error: Error, passcodeAvailable: Bool) -> AppAuthenticationResult {
        guard let laError = error as? LAError else {
            return passcodeAvailable ? .requiresPasscode : .failure
        }

        switch laError.code {
        case .userCancel, .appCancel, .systemCancel:
            return .cancelled
        case .userFallback, .authenticationFailed:
            return passcodeAvailable ? .requiresPasscode : .failure
        case .biometryNotAvailable, .biometryNotEnrolled, .passcodeNotSet, .biometryLockout:
            return passcodeAvailable ? .requiresPasscode : .unavailable
        default:
            return passcodeAvailable ? .requiresPasscode : .failure
        }
    }
}

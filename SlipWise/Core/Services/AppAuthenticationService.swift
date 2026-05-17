import Foundation
import LocalAuthentication

enum AppAuthenticationResult: Equatable {
    case success
    case requiresPasscode
    case failure
}

final class AppAuthenticationService {
    func canAuthenticateWithBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func authenticateForSensitiveAction(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }

        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        } catch {
            return false
        }
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
            return passcodeAvailable ? .requiresPasscode : .failure
        }

        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            return success ? .success : (passcodeAvailable ? .requiresPasscode : .failure)
        } catch {
            return passcodeAvailable ? .requiresPasscode : .failure
        }
    }

    func authenticateForAppLock(reason: String) async -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = ""
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }

        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        } catch {
            return false
        }
    }
}

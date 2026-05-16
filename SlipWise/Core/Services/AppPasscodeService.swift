import CryptoKit
import Foundation

final class AppPasscodeService {
    func hasPasscode(settings: UserSettings?) -> Bool {
        guard let hash = settings?.editDeletePasswordHash else { return false }
        return !hash.isEmpty
    }

    func setPasscode(_ passcode: String, settings: UserSettings) {
        guard isValidPasscode(passcode) else { return }
        settings.editDeletePasswordHash = hash(passcode)
        settings.isEditDeletePasswordEnabled = true
        settings.touch()
    }

    func clearPasscode(settings: UserSettings) {
        settings.editDeletePasswordHash = nil
        settings.isEditDeletePasswordEnabled = false
        settings.touch()
    }

    func verifyPasscode(_ passcode: String, settings: UserSettings?) -> Bool {
        guard
            let settings,
            let expectedHash = settings.editDeletePasswordHash
        else { return false }

        return hash(passcode) == expectedHash
    }

    func isValidPasscode(_ passcode: String) -> Bool {
        passcode.count >= 4 && passcode.allSatisfy(\.isNumber)
    }

    private func hash(_ passcode: String) -> String {
        let digest = SHA256.hash(data: Data(passcode.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

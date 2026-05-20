import CryptoKit
import Foundation

final class AppPasscodeService {
    static func hash(_ passcode: String) -> String {
        let digest = SHA256.hash(data: Data(passcode.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func verify(_ passcode: String, hash: String) -> Bool {
        Self.hash(passcode) == hash
    }

    static func isValidFourDigitPasscode(_ passcode: String) -> Bool {
        passcode.count == 4 && passcode.allSatisfy(\.isNumber)
    }

    func hasPasscode(settings: UserSettings?) -> Bool {
        guard let hash = settings?.editDeletePasswordHash else { return false }
        return !hash.isEmpty
    }

    func setPasscode(_ passcode: String, settings: UserSettings) {
        guard isValidPasscode(passcode) else { return }
        settings.editDeletePasswordHash = Self.hash(passcode)
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

        return Self.verify(passcode, hash: expectedHash)
    }

    func isValidPasscode(_ passcode: String) -> Bool {
        Self.isValidFourDigitPasscode(passcode)
    }
}

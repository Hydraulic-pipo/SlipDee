import Foundation

extension String {
    var containsDigit: Bool {
        rangeOfCharacter(from: .decimalDigits) != nil
    }
}

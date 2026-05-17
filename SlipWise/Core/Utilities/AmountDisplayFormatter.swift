import Foundation

enum AmountDisplayFormatter {
    static func display(
        amount: Double,
        currencyCode: String = CurrencyCode.thb,
        isHidden: Bool,
        showSign: Bool = false,
        isIncome: Bool = false
    ) -> String {
        let prefix: String
        if showSign {
            prefix = isIncome ? "+" : "-"
        } else {
            prefix = ""
        }

        guard !isHidden else {
            return "\(prefix)\(CurrencyFormatter.maskedAmountString(currencyCode: currencyCode))"
        }

        let formatted = CurrencyFormatter.bahtString(from: abs(amount))
        return showSign ? "\(prefix)\(formatted)" : CurrencyFormatter.bahtString(from: amount)
    }
}

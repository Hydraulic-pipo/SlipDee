import Foundation

enum CurrencyFormatter {
    static let bahtFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "THB"
        formatter.locale = Locale(identifier: "th_TH")
        formatter.currencySymbol = "฿"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    static func bahtString(from amount: Double) -> String {
        bahtFormatter.string(from: NSNumber(value: amount)) ?? "฿0.00"
    }

    static func bahtInputString(from amountText: String) -> String {
        guard let amount = Double(amountText.replacingOccurrences(of: ",", with: "")) else {
            return "฿0.00"
        }

        return bahtString(from: amount)
    }
}

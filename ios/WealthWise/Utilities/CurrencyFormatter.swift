import Foundation

// MARK: - Currency Formatter

enum CurrencyFormatter {
    private static let cad: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "CAD"
        f.currencySymbol = "$"
        f.locale = Locale(identifier: "en_CA")
        f.maximumFractionDigits = 0
        f.minimumFractionDigits = 0
        return f
    }()

    private static let cadWithCents: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "CAD"
        f.currencySymbol = "$"
        f.locale = Locale(identifier: "en_CA")
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        return f
    }()

    /// Formats a dollar amount without cents (e.g. "$12,500")
    static func format(_ amount: Double) -> String {
        cad.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }

    /// Formats a dollar amount with cents (e.g. "$9.99")
    static func formatWithCents(_ amount: Double) -> String {
        cadWithCents.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }

    /// Formats a compact amount (e.g. "$1.2M", "$450K")
    static func formatCompact(_ amount: Double) -> String {
        switch abs(amount) {
        case 1_000_000...:
            return String(format: "$%.1fM", amount / 1_000_000)
        case 1_000...:
            return String(format: "$%.0fK", amount / 1_000)
        default:
            return format(amount)
        }
    }

    /// Formats a percentage (e.g. "7.0%")
    static func formatPercent(_ value: Double, decimals: Int = 1) -> String {
        String(format: "%.\(decimals)f%%", value)
    }
}

import Foundation

enum TaxCalculator {
    // 2024/2025 Federal Tax Brackets (Canada)
    struct TaxBracket {
        let lowerBound: Double
        let upperBound: Double
        let rate: Double
    }

    static let federalBrackets: [TaxBracket] = [
        TaxBracket(lowerBound: 0, upperBound: 55_867, rate: 0.15),
        TaxBracket(lowerBound: 55_867, upperBound: 111_733, rate: 0.205),
        TaxBracket(lowerBound: 111_733, upperBound: 154_906, rate: 0.26),
        TaxBracket(lowerBound: 154_906, upperBound: 220_000, rate: 0.29),
        TaxBracket(lowerBound: 220_000, upperBound: .infinity, rate: 0.33),
    ]

    // Provincial top marginal rates (simplified)
    static let provincialTopRates: [String: Double] = [
        "AB": 0.15, "BC": 0.205, "MB": 0.174, "NB": 0.195,
        "NL": 0.218, "NS": 0.21, "NT": 0.1405, "NU": 0.115,
        "ON": 0.1316, "PE": 0.185, "QC": 0.2575, "SK": 0.145,
        "YT": 0.15,
    ]

    // Provincial base rates for first bracket
    static let provincialBaseRates: [String: Double] = [
        "AB": 0.10, "BC": 0.0506, "MB": 0.108, "NB": 0.094,
        "NL": 0.087, "NS": 0.0879, "NT": 0.059, "NU": 0.04,
        "ON": 0.0505, "PE": 0.098, "QC": 0.14, "SK": 0.105,
        "YT": 0.064,
    ]

    /// Calculate federal tax on income
    static func federalTax(on income: Double) -> Double {
        var tax = 0.0
        for bracket in federalBrackets {
            if income <= bracket.lowerBound { break }
            let taxableInBracket = min(income, bracket.upperBound) - bracket.lowerBound
            tax += taxableInBracket * bracket.rate
        }
        return tax
    }

    /// Estimate marginal tax rate (federal + provincial)
    static func marginalRate(income: Double, province: String) -> Double {
        let federalRate = federalMarginalRate(income: income)
        let provincialRate = provincialBaseRates[province] ?? 0.10
        return federalRate + provincialRate
    }

    /// Estimate RRSP tax refund for a given contribution
    static func rrspTaxRefund(contribution: Double, income: Double, province: String) -> Double {
        let rate = marginalRate(income: income, province: province)
        return contribution * rate
    }

    /// Net cost of RRSP contribution after tax refund
    static func rrspNetCost(contribution: Double, income: Double, province: String) -> Double {
        return contribution - rrspTaxRefund(contribution: contribution, income: income, province: province)
    }

    private static func federalMarginalRate(income: Double) -> Double {
        for bracket in federalBrackets.reversed() {
            if income > bracket.lowerBound {
                return bracket.rate
            }
        }
        return federalBrackets[0].rate
    }
}

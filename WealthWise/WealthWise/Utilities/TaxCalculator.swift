import Foundation

enum TaxCalculator {
    // 2025 Federal Tax Brackets (Canada) — updated per CRA
    struct TaxBracket {
        let lowerBound: Double
        let upperBound: Double
        let rate: Double
    }

    static let federalBrackets: [TaxBracket] = [
        TaxBracket(lowerBound: 0, upperBound: 57_375, rate: 0.15),
        TaxBracket(lowerBound: 57_375, upperBound: 114_750, rate: 0.205),
        TaxBracket(lowerBound: 114_750, upperBound: 158_468, rate: 0.26),
        TaxBracket(lowerBound: 158_468, upperBound: 220_000, rate: 0.29),
        TaxBracket(lowerBound: 220_000, upperBound: .infinity, rate: 0.33),
    ]

    /// 2026 RRSP annual deduction limit
    static let rrspMaxDeduction: Double = 33_810

    /// 2026 TFSA annual contribution limit
    static let tfsaAnnualLimit: Double = 7_000

    /// Cumulative TFSA room if eligible since 2009 (through 2026)
    static let tfsaCumulativeRoom: Double = 109_000

    /// FHSA annual and lifetime limits
    static let fhsaAnnualLimit: Double = 8_000
    static let fhsaLifetimeLimit: Double = 40_000

    /// RESP lifetime limit per beneficiary
    static let respLifetimeLimit: Double = 50_000

    /// CESG annual maximum (20% on first $2,500 contributed)
    static let cespAnnualMax: Double = 500

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

import Foundation

// MARK: - Tax Calculator
// Provides Canadian marginal tax rate calculations for RRSP optimization.
// Rates are based on 2025 tax year brackets. Update annually.

enum TaxCalculator {

    // MARK: - Federal Tax Brackets (2025)
    // Source: CRA https://www.canada.ca/en/revenue-agency/

    private static let federalBrackets: [(threshold: Double, rate: Double)] = [
        (0,          0.15),   // 15% on first $57,375
        (57_375,     0.205),  // 20.5% on $57,375–$114,750
        (114_750,    0.26),   // 26% on $114,750–$158,519
        (158_519,    0.29),   // 29% on $158,519–$220,000
        (220_000,    0.33),   // 33% on income over $220,000
    ]

    // MARK: - Provincial Tax Brackets (2025, simplified top marginal)
    // These are combined (federal + provincial) top marginal rates for simplicity.
    // In production, use full bracket tables per province.

    private static let provincialTopRates: [CanadianProvince: Double] = [
        .ab: 0.1500, .bc: 0.1680, .mb: 0.1750, .nb: 0.1930,
        .nl: 0.2130, .ns: 0.2100, .nt: 0.1405, .nu: 0.1150,
        .on: 0.1316, .pe: 0.1875, .qc: 0.2575, .sk: 0.1475, .yt: 0.1540,
    ]

    // MARK: - Marginal Tax Rate

    /// Returns the combined federal + provincial marginal tax rate for a given income.
    ///
    /// - Parameters:
    ///   - income: Annual taxable income in CAD
    ///   - province: Province of residence
    /// - Returns: Combined marginal rate as a decimal (e.g. 0.435 for 43.5%)
    static func marginalRate(income: Double, province: CanadianProvince) -> Double {
        let federalRate = federalMarginalRate(income: income)
        let provincialRate = provincialTopRates[province] ?? 0.13
        return min(federalRate + provincialRate, 0.54) // Cap at ~54% (highest Canadian rate)
    }

    /// Federal marginal rate only.
    static func federalMarginalRate(income: Double) -> Double {
        var rate = federalBrackets[0].rate
        for bracket in federalBrackets {
            if income > bracket.threshold {
                rate = bracket.rate
            } else {
                break
            }
        }
        return rate
    }

    // MARK: - RRSP Tax Refund Estimate

    /// Estimates the tax refund from an RRSP contribution.
    ///
    /// - Parameters:
    ///   - income: Annual income before RRSP contribution
    ///   - contribution: Amount contributed to RRSP
    ///   - province: Province of residence
    /// - Returns: Estimated tax refund amount
    static func rrspRefundEstimate(income: Double, contribution: Double, province: CanadianProvince) -> Double {
        let rate = marginalRate(income: income, province: province)
        return contribution * rate
    }

    /// Calculates the net out-of-pocket cost of an RRSP contribution after tax refund.
    ///
    /// - Parameters:
    ///   - contribution: Amount contributed to RRSP
    ///   - income: Annual income
    ///   - province: Province of residence
    /// - Returns: Net cost (contribution minus estimated tax refund)
    static func rrspNetCost(contribution: Double, income: Double, province: CanadianProvince) -> Double {
        let refund = rrspRefundEstimate(income: income, contribution: contribution, province: province)
        return contribution - refund
    }

    // MARK: - Fee Drag Calculator

    /// Calculates how much a management expense ratio (MER) difference costs over time.
    ///
    /// - Parameters:
    ///   - portfolioValue: Starting portfolio value
    ///   - highMER: Higher MER (e.g. 2.3 for 2.3% mutual fund)
    ///   - lowMER: Lower MER (e.g. 0.2 for 0.2% index ETF)
    ///   - annualReturn: Gross annual return before fees (e.g. 7.0)
    ///   - years: Investment horizon
    /// - Returns: Cost of the fee difference (how much more you'd have with the low MER)
    static func feeDragCost(
        portfolioValue: Double,
        highMER: Double,
        lowMER: Double,
        annualReturn: Double,
        years: Int
    ) -> (highMERValue: Double, lowMERValue: Double, savings: Double) {
        let highNetReturn = annualReturn - highMER
        let lowNetReturn = annualReturn - lowMER

        let highValue = portfolioValue * pow(1 + highNetReturn / 100, Double(years))
        let lowValue = portfolioValue * pow(1 + lowNetReturn / 100, Double(years))

        return (highValue, lowValue, lowValue - highValue)
    }
}

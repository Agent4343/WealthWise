import Foundation

// MARK: - Compound Interest Calculator

enum CompoundInterestCalculator {

    /// Calculates the future value of a lump-sum investment plus regular monthly contributions.
    ///
    /// - Parameters:
    ///   - principal: Initial lump-sum investment
    ///   - monthlyContribution: Regular monthly deposit
    ///   - annualRate: Annual interest rate as a percentage (e.g. 7.0 for 7%)
    ///   - years: Number of years to compound
    /// - Returns: Future value
    static func futureValue(
        principal: Double,
        monthlyContribution: Double,
        annualRate: Double,
        years: Int
    ) -> Double {
        guard years > 0, annualRate >= 0 else { return principal }

        let r = annualRate / 100 / 12    // monthly rate
        let n = Double(years * 12)       // total months

        // Future value of lump sum: P × (1 + r)^n
        let pvFuture = principal * pow(1 + r, n)

        // Future value of annuity: PMT × [((1 + r)^n − 1) / r]
        let fvContributions: Double
        if r == 0 {
            fvContributions = monthlyContribution * n
        } else {
            fvContributions = monthlyContribution * ((pow(1 + r, n) - 1) / r)
        }

        return pvFuture + fvContributions
    }

    /// Calculates the cost of waiting — how much less you'd have if you started N years later.
    ///
    /// - Parameters:
    ///   - monthlyContribution: Monthly investment amount
    ///   - annualRate: Annual rate as percentage
    ///   - yearsIfStartNow: Years to retirement if starting today
    ///   - yearsDelay: Years of delay before starting
    /// - Returns: Tuple of (startNow value, startLater value, difference)
    static func costOfWaiting(
        monthlyContribution: Double,
        annualRate: Double,
        yearsIfStartNow: Int,
        yearsDelay: Int
    ) -> (startNow: Double, startLater: Double, difference: Double) {
        let startNow = futureValue(
            principal: 0,
            monthlyContribution: monthlyContribution,
            annualRate: annualRate,
            years: yearsIfStartNow
        )
        let startLater = futureValue(
            principal: 0,
            monthlyContribution: monthlyContribution,
            annualRate: annualRate,
            years: max(0, yearsIfStartNow - yearsDelay)
        )
        return (startNow, startLater, startNow - startLater)
    }

    /// Calculates safe withdrawal amount per month from a retirement portfolio.
    /// Uses the 4% Safe Withdrawal Rate rule.
    ///
    /// - Parameter portfolioValue: Total retirement portfolio value
    /// - Returns: Monthly withdrawal amount (4% annual / 12)
    static func monthlyWithdrawal(portfolioValue: Double) -> Double {
        (portfolioValue * 0.04) / 12
    }
}

// MARK: - FIRE Number Calculator

enum FIRECalculator {

    /// Calculates the portfolio needed to retire on investment returns alone.
    ///
    /// - Parameters:
    ///   - monthlyExpenses: Expected monthly expenses in retirement
    ///   - withdrawalRate: Safe withdrawal rate as percentage (default 4.0)
    /// - Returns: Target portfolio value (the "FIRE number")
    static func fireNumber(monthlyExpenses: Double, withdrawalRate: Double = 4.0) -> Double {
        guard withdrawalRate > 0 else { return 0 }
        let annualExpenses = monthlyExpenses * 12
        return annualExpenses / (withdrawalRate / 100)
    }

    /// Estimates years to reach FIRE number.
    ///
    /// - Parameters:
    ///   - currentSavings: Current invested assets
    ///   - monthlyContribution: Monthly investment amount
    ///   - annualRate: Expected annual return as percentage
    ///   - fireNumber: Target portfolio value
    /// - Returns: Estimated years to FIRE (nil if unachievable with given rate)
    static func yearsToFIRE(
        currentSavings: Double,
        monthlyContribution: Double,
        annualRate: Double,
        fireNumber: Double
    ) -> Int? {
        guard monthlyContribution > 0, fireNumber > 0 else { return nil }

        var balance = currentSavings
        let monthlyRate = annualRate / 100 / 12
        var months = 0
        let maxMonths = 600 // 50 years cap

        while balance < fireNumber && months < maxMonths {
            balance = balance * (1 + monthlyRate) + monthlyContribution
            months += 1
        }

        return months < maxMonths ? Int(ceil(Double(months) / 12)) : nil
    }
}

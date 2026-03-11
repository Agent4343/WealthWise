import Foundation

enum CompoundInterestCalculator {

    struct RetirementResult {
        let finalBalance: Double
        let totalContributions: Double
        let totalInterestEarned: Double
        let monthlyIncomeAt4Percent: Double
        let yearByYearBalances: [YearBalance]
    }

    struct YearBalance: Identifiable {
        let id: Int
        let year: Int
        let age: Int
        let balance: Double
        let contributions: Double
        let interestEarned: Double
    }

    /// Calculate retirement portfolio growth with monthly contributions
    static func retirementBuilder(
        currentAge: Int,
        retirementAge: Int,
        monthlyContribution: Double,
        annualReturn: Double,
        existingSavings: Double
    ) -> RetirementResult {
        let years = retirementAge - currentAge
        guard years > 0 else {
            return RetirementResult(
                finalBalance: existingSavings,
                totalContributions: existingSavings,
                totalInterestEarned: 0,
                monthlyIncomeAt4Percent: existingSavings * 0.04 / 12,
                yearByYearBalances: []
            )
        }

        let monthlyRate = annualReturn / 12
        var balance = existingSavings
        var totalContributions = existingSavings
        var yearBalances: [YearBalance] = []

        for year in 1...years {
            let startBalance = balance
            for _ in 1...12 {
                balance += monthlyContribution
                balance *= (1 + monthlyRate)
            }
            let yearContributions = monthlyContribution * 12
            totalContributions += yearContributions
            let yearInterest = balance - startBalance - yearContributions

            yearBalances.append(YearBalance(
                id: year,
                year: year,
                age: currentAge + year,
                balance: balance,
                contributions: totalContributions,
                interestEarned: balance - totalContributions
            ))
        }

        return RetirementResult(
            finalBalance: balance,
            totalContributions: totalContributions,
            totalInterestEarned: balance - totalContributions,
            monthlyIncomeAt4Percent: balance * 0.04 / 12,
            yearByYearBalances: yearBalances
        )
    }

    /// Calculate TFSA growth (tax-free)
    static func tfsaGrowth(
        currentAge: Int,
        annualContribution: Double,
        annualReturn: Double,
        existingBalance: Double = 0
    ) -> RetirementResult {
        return retirementBuilder(
            currentAge: currentAge,
            retirementAge: 65,
            monthlyContribution: annualContribution / 12,
            annualReturn: annualReturn,
            existingSavings: existingBalance
        )
    }

    /// Calculate fee drag — how much a higher MER costs over time
    static func feeDrag(
        portfolioValue: Double,
        merLow: Double,
        merHigh: Double,
        years: Int,
        annualReturn: Double = 0.07
    ) -> (lowFeeBalance: Double, highFeeBalance: Double, costOfHighFees: Double) {
        let lowBalance = futureValue(
            present: portfolioValue,
            rate: annualReturn - merLow,
            years: years
        )
        let highBalance = futureValue(
            present: portfolioValue,
            rate: annualReturn - merHigh,
            years: years
        )
        return (lowBalance, highBalance, lowBalance - highBalance)
    }

    /// Calculate FIRE number (Financial Independence, Retire Early)
    static func fireNumber(
        monthlyExpenses: Double,
        withdrawalRate: Double = 0.04
    ) -> Double {
        let annualExpenses = monthlyExpenses * 12
        return annualExpenses / withdrawalRate
    }

    /// Simple future value calculation
    static func futureValue(present: Double, rate: Double, years: Int) -> Double {
        return present * pow(1 + rate, Double(years))
    }

    /// Calculate the cost of waiting — what delaying N years costs you
    static func costOfWaiting(
        monthlyContribution: Double,
        annualReturn: Double,
        yearsToRetirement: Int,
        yearsDelayed: Int
    ) -> (onTime: Double, delayed: Double, costOfWaiting: Double) {
        let onTime = retirementBuilder(
            currentAge: 30,
            retirementAge: 30 + yearsToRetirement,
            monthlyContribution: monthlyContribution,
            annualReturn: annualReturn,
            existingSavings: 0
        ).finalBalance

        let delayed = retirementBuilder(
            currentAge: 30,
            retirementAge: 30 + yearsToRetirement - yearsDelayed,
            monthlyContribution: monthlyContribution,
            annualReturn: annualReturn,
            existingSavings: 0
        ).finalBalance

        return (onTime, delayed, onTime - delayed)
    }
}

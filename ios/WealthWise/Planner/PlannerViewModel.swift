import Foundation

// MARK: - Planner ViewModel

@MainActor
final class PlannerViewModel: ObservableObject {

    // MARK: - Retirement Builder

    @Published var retirementAge: Double = 32
    @Published var retirementTargetAge: Double = 65
    @Published var retirementMonthlyContribution: Double = 500
    @Published var retirementExistingSavings: Double = 10000
    @Published var retirementAnnualRate: Double = 7.0

    var retirementProjectedValue: Double {
        let years = max(0, Int(retirementTargetAge - retirementAge))
        return CompoundInterestCalculator.futureValue(
            principal: retirementExistingSavings,
            monthlyContribution: retirementMonthlyContribution,
            annualRate: retirementAnnualRate,
            years: years
        )
    }

    var retirementMonthlyIncome: Double {
        CompoundInterestCalculator.monthlyWithdrawal(portfolioValue: retirementProjectedValue)
    }

    var costOfWaiting5Years: Double {
        let years = max(0, Int(retirementTargetAge - retirementAge))
        let (_, later, diff) = CompoundInterestCalculator.costOfWaiting(
            monthlyContribution: retirementMonthlyContribution,
            annualRate: retirementAnnualRate,
            yearsIfStartNow: years,
            yearsDelay: 5
        )
        return diff
    }

    // MARK: - TFSA Optimizer

    @Published var tfsaCurrentAge: Double = 30
    @Published var tfsaAnnualContribution: Double = 6_500
    @Published var tfsaRate: Double = 7.0

    var tfsaValueAt65: Double {
        let years = max(0, 65 - Int(tfsaCurrentAge))
        return CompoundInterestCalculator.futureValue(
            principal: 0,
            monthlyContribution: tfsaAnnualContribution / 12,
            annualRate: tfsaRate,
            years: years
        )
    }

    var tfsaTaxSaved: Double {
        // Tax saved vs taxable account at 43% average marginal rate
        let taxableValue = CompoundInterestCalculator.futureValue(
            principal: 0,
            monthlyContribution: tfsaAnnualContribution / 12,
            annualRate: tfsaRate * 0.57, // after 43% tax on returns
            years: max(0, 65 - Int(tfsaCurrentAge))
        )
        return tfsaValueAt65 - taxableValue
    }

    // MARK: - RRSP Tax Saver

    @Published var rrspIncome: Double = 80_000
    @Published var rrspProvince: CanadianProvince = .on
    @Published var rrspContribution: Double = 10_000

    var rrspRefundEstimate: Double {
        TaxCalculator.rrspRefundEstimate(
            income: rrspIncome,
            contribution: rrspContribution,
            province: rrspProvince
        )
    }

    var rrspNetCost: Double {
        TaxCalculator.rrspNetCost(
            contribution: rrspContribution,
            income: rrspIncome,
            province: rrspProvince
        )
    }

    // MARK: - Fee Drag Calculator

    @Published var feeDragPortfolio: Double = 100_000
    @Published var feeDragHighMER: Double = 2.3  // typical Canadian mutual fund
    @Published var feeDragLowMER: Double = 0.20  // typical index ETF
    @Published var feeDragYears: Double = 25

    var feeDragResult: (highMERValue: Double, lowMERValue: Double, savings: Double) {
        TaxCalculator.feeDragCost(
            portfolioValue: feeDragPortfolio,
            highMER: feeDragHighMER,
            lowMER: feeDragLowMER,
            annualReturn: 7.0,
            years: Int(feeDragYears)
        )
    }

    // MARK: - FIRE Number

    @Published var fireMonthlyExpenses: Double = 4_000
    @Published var fireWithdrawalRate: Double = 4.0
    @Published var fireCurrentSavings: Double = 50_000
    @Published var fireMonthlyContribution: Double = 2_000
    @Published var fireAnnualRate: Double = 7.0

    var fireNumber: Double {
        FIRECalculator.fireNumber(
            monthlyExpenses: fireMonthlyExpenses,
            withdrawalRate: fireWithdrawalRate
        )
    }

    var yearsToFIRE: Int? {
        FIRECalculator.yearsToFIRE(
            currentSavings: fireCurrentSavings,
            monthlyContribution: fireMonthlyContribution,
            annualRate: fireAnnualRate,
            fireNumber: fireNumber
        )
    }
}

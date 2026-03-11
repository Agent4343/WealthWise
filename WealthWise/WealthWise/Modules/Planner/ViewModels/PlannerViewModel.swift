import Foundation
import SwiftUI

@MainActor
final class PlannerViewModel: ObservableObject {
    // Retirement Builder
    @Published var retCurrentAge: Int = 30
    @Published var retRetirementAge: Int = 65
    @Published var retMonthlyAmount: String = "500"
    @Published var retAnnualReturn: Double = 0.07
    @Published var retExistingSavings: String = "0"
    @Published var retResult: CompoundInterestCalculator.RetirementResult?

    // TFSA Optimizer
    @Published var tfsaAge: Int = 30
    @Published var tfsaAnnualContribution: String = "7000"
    @Published var tfsaAnnualReturn: Double = 0.07
    @Published var tfsaExistingBalance: String = "0"
    @Published var tfsaResult: CompoundInterestCalculator.RetirementResult?

    // RRSP Tax Saver
    @Published var rrspIncome: String = "85000"
    @Published var rrspProvince: Province = .on
    @Published var rrspContribution: String = "10000"
    @Published var rrspTaxRefund: Double?
    @Published var rrspNetCost: Double?

    // Fee Drag Calculator
    @Published var feePortfolioValue: String = "100000"
    @Published var feeLowMER: Double = 0.002
    @Published var feeHighMER: Double = 0.023
    @Published var feeYears: Int = 30
    @Published var feeLowBalance: Double?
    @Published var feeHighBalance: Double?
    @Published var feeDragCost: Double?

    // FIRE Number
    @Published var fireMonthlyExpenses: String = "4000"
    @Published var fireWithdrawalRate: Double = 0.04
    @Published var fireNumber: Double?

    func calculateRetirement() {
        let monthly = Double(retMonthlyAmount) ?? 0
        let existing = Double(retExistingSavings) ?? 0
        retResult = CompoundInterestCalculator.retirementBuilder(
            currentAge: retCurrentAge,
            retirementAge: retRetirementAge,
            monthlyContribution: monthly,
            annualReturn: retAnnualReturn,
            existingSavings: existing
        )
    }

    func calculateTFSA() {
        let annual = Double(tfsaAnnualContribution) ?? 0
        let existing = Double(tfsaExistingBalance) ?? 0
        tfsaResult = CompoundInterestCalculator.tfsaGrowth(
            currentAge: tfsaAge,
            annualContribution: annual,
            annualReturn: tfsaAnnualReturn,
            existingBalance: existing
        )
    }

    func calculateRRSP() {
        let income = Double(rrspIncome) ?? 0
        let contribution = Double(rrspContribution) ?? 0
        rrspTaxRefund = TaxCalculator.rrspTaxRefund(
            contribution: contribution,
            income: income,
            province: rrspProvince.rawValue
        )
        rrspNetCost = TaxCalculator.rrspNetCost(
            contribution: contribution,
            income: income,
            province: rrspProvince.rawValue
        )
    }

    func calculateFeeDrag() {
        let portfolio = Double(feePortfolioValue) ?? 0
        let result = CompoundInterestCalculator.feeDrag(
            portfolioValue: portfolio,
            merLow: feeLowMER,
            merHigh: feeHighMER,
            years: feeYears
        )
        feeLowBalance = result.lowFeeBalance
        feeHighBalance = result.highFeeBalance
        feeDragCost = result.costOfHighFees
    }

    func calculateFIRE() {
        let expenses = Double(fireMonthlyExpenses) ?? 0
        fireNumber = CompoundInterestCalculator.fireNumber(
            monthlyExpenses: expenses,
            withdrawalRate: fireWithdrawalRate
        )
    }
}

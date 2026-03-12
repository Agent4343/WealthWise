import Foundation
import SwiftUI

@MainActor
final class PlannerViewModel: ObservableObject {

    enum PlanMode: String {
        case solo, couple
    }

    struct AdequacyResult {
        let icon: String
        let title: String
        let message: String
        let color: Color
    }

    // MARK: - Retirement Builder
    @Published var retMode: PlanMode = .solo
    @Published var retCurrentAge: Int = 30
    @Published var retRetirementAge: Int = 65
    @Published var retMonthlyAmount: String = "500"
    @Published var retAnnualReturn: Double = 0.07
    @Published var retExistingSavings: String = "0"
    @Published var retResult: CompoundInterestCalculator.RetirementResult?

    // Partner
    @Published var retPartnerAge: Int = 30
    @Published var retPartnerRetirementAge: Int = 65
    @Published var retPartnerMonthly: String = "300"
    @Published var retPartnerSavings: String = "0"
    @Published var retPartnerReturn: Double = 0.07
    @Published var retPartnerResult: CompoundInterestCalculator.RetirementResult?

    // Desired income & adequacy
    @Published var retDesiredIncome: String = "4000"
    @Published var retAdequacy: AdequacyResult?

    // MARK: - TFSA Optimizer
    @Published var tfsaAge: Int = 30
    @Published var tfsaAnnualContribution: String = "7000"
    @Published var tfsaAnnualReturn: Double = 0.07
    @Published var tfsaExistingBalance: String = "0"
    @Published var tfsaResult: CompoundInterestCalculator.RetirementResult?

    // MARK: - RRSP Tax Saver
    @Published var rrspIncome: String = "85000"
    @Published var rrspProvince: Province = .on
    @Published var rrspContribution: String = "10000"
    @Published var rrspTaxRefund: Double?
    @Published var rrspNetCost: Double?

    // MARK: - Fee Drag Calculator
    @Published var feePortfolioValue: String = "100000"
    @Published var feeLowMER: Double = 0.002
    @Published var feeHighMER: Double = 0.023
    @Published var feeYears: Int = 30
    @Published var feeLowBalance: Double?
    @Published var feeHighBalance: Double?
    @Published var feeDragCost: Double?

    // MARK: - FIRE Number
    @Published var fireMode: PlanMode = .solo
    @Published var fireMonthlyExpenses: String = "4000"
    @Published var fireWithdrawalRate: Double = 0.04
    @Published var fireNumber: Double?
    @Published var fireYearsToTarget: Double?

    // FIRE time-to-target inputs
    @Published var fireCurrentAge: Int = 30
    @Published var fireCurrentSavings: String = "50000"
    @Published var fireMonthlyContrib: String = "1500"
    @Published var fireReturnRate: Double = 0.07

    // FIRE partner
    @Published var firePartnerSavings: String = "30000"
    @Published var firePartnerContrib: String = "1000"
    @Published var firePartnerReturn: Double = 0.07

    // MARK: - Calculations

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

        if retMode == .couple {
            let partnerMonthly = Double(retPartnerMonthly) ?? 0
            let partnerSavings = Double(retPartnerSavings) ?? 0
            retPartnerResult = CompoundInterestCalculator.retirementBuilder(
                currentAge: retPartnerAge,
                retirementAge: retPartnerRetirementAge,
                monthlyContribution: partnerMonthly,
                annualReturn: retPartnerReturn,
                existingSavings: partnerSavings
            )
        } else {
            retPartnerResult = nil
        }

        // Adequacy check
        let desired = Double(retDesiredIncome) ?? 0
        if desired > 0, let result = retResult {
            var projectedMonthly: Double
            if retMode == .couple, let partnerResult = retPartnerResult {
                projectedMonthly = ((result.finalBalance + partnerResult.finalBalance) * 0.04) / 12
            } else {
                projectedMonthly = result.monthlyIncomeAt4Percent
            }

            let pct = (projectedMonthly / desired) * 100

            if pct >= 120 {
                let surplus = projectedMonthly - desired
                retAdequacy = AdequacyResult(
                    icon: "🎉",
                    title: "Well Above Target",
                    message: "Projected \(CurrencyFormatter.format(projectedMonthly, compact: true))/mo — \(Int(pct))% of your target. Extra \(CurrencyFormatter.format(surplus, compact: true))/mo for travel, gifts, or legacy.",
                    color: .green
                )
            } else if pct >= 100 {
                let surplus = projectedMonthly - desired
                retAdequacy = AdequacyResult(
                    icon: "✅",
                    title: "On Track",
                    message: "Projected \(CurrencyFormatter.format(projectedMonthly, compact: true))/mo covers your target with \(CurrencyFormatter.format(surplus, compact: true))/mo to spare.",
                    color: .green
                )
            } else if pct >= 75 {
                let gap = desired - projectedMonthly
                retAdequacy = AdequacyResult(
                    icon: "⚠️",
                    title: "Close But Short",
                    message: "Projected \(CurrencyFormatter.format(projectedMonthly, compact: true))/mo — \(Int(pct))% of target. Short by \(CurrencyFormatter.format(gap, compact: true))/mo. Consider increasing contributions.",
                    color: .yellow
                )
            } else {
                let gap = desired - projectedMonthly
                retAdequacy = AdequacyResult(
                    icon: "🚨",
                    title: "Significant Gap",
                    message: "Projected \(CurrencyFormatter.format(projectedMonthly, compact: true))/mo — only \(Int(pct))% of your \(CurrencyFormatter.format(desired, compact: true))/mo target. Gap of \(CurrencyFormatter.format(gap, compact: true))/mo.",
                    color: .red
                )
            }
        } else {
            retAdequacy = nil
        }
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
        let target = CompoundInterestCalculator.fireNumber(
            monthlyExpenses: expenses,
            withdrawalRate: fireWithdrawalRate
        )
        fireNumber = target

        // Calculate years to FIRE
        var totalSavings = Double(fireCurrentSavings) ?? 0
        var totalMonthly = Double(fireMonthlyContrib) ?? 0
        var avgReturn = fireReturnRate

        if fireMode == .couple {
            let partnerSavings = Double(firePartnerSavings) ?? 0
            let partnerContrib = Double(firePartnerContrib) ?? 0
            totalSavings += partnerSavings
            totalMonthly += partnerContrib
            // Weighted average return
            if totalSavings > 0 {
                let mySavings = Double(fireCurrentSavings) ?? 0
                avgReturn = (fireReturnRate * mySavings + firePartnerReturn * partnerSavings) / totalSavings
            } else {
                avgReturn = (fireReturnRate + firePartnerReturn) / 2
            }
        }

        if totalSavings >= target {
            fireYearsToTarget = 0
        } else if totalMonthly <= 0 {
            fireYearsToTarget = nil
        } else {
            let monthlyRate = avgReturn / 12
            var balance = totalSavings
            var months = 0
            let maxMonths = 100 * 12

            while balance < target && months < maxMonths {
                balance = (balance + totalMonthly) * (1 + monthlyRate)
                months += 1
            }
            fireYearsToTarget = Double(months) / 12.0
        }
    }
}

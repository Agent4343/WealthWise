import Foundation

/// Money Score: a 0–100 financial health score composed of 7 weighted components.
enum MoneyScoreCalculator {

    struct ScoreResult {
        let totalScore: Int
        let breakdown: [ScoreComponent]
        let grade: Grade
        let recommendations: [String]
    }

    struct ScoreComponent: Identifiable {
        let id: String
        let name: String
        let score: Int        // 0–100 for this component
        let weight: Double    // weight in overall score
        let weighted: Double  // score * weight
        let description: String
        let suggestion: String
    }

    enum Grade: String {
        case excellent = "Excellent"
        case great = "Great"
        case good = "Good"
        case fair = "Fair"
        case needsWork = "Needs Work"

        var emoji: String {
            switch self {
            case .excellent: return "star.fill"
            case .great: return "hand.thumbsup.fill"
            case .good: return "checkmark.circle.fill"
            case .fair: return "exclamationmark.triangle.fill"
            case .needsWork: return "arrow.up.circle.fill"
            }
        }

        static func from(score: Int) -> Grade {
            switch score {
            case 85...100: return .excellent
            case 70..<85: return .great
            case 55..<70: return .good
            case 40..<55: return .fair
            default: return .needsWork
            }
        }
    }

    /// Calculate the full Money Score from a financial profile
    static func calculate(profile: FinancialProfile) -> ScoreResult {
        let income = IncomeBracket(rawValue: profile.incomeBracket)?.midpoint ?? 75_000
        let monthlyIncome = income / 12

        var components: [ScoreComponent] = []

        // 1. Savings Rate (20% weight)
        let savingsRate = monthlyIncome > 0 ? profile.monthlyContribution / monthlyIncome : 0
        let savingsScore = min(100, Int(savingsRate / 0.20 * 100)) // 20% savings rate = 100
        components.append(ScoreComponent(
            id: "savings_rate",
            name: "Savings Rate",
            score: savingsScore,
            weight: 0.20,
            weighted: Double(savingsScore) * 0.20,
            description: "You save \(String(format: "%.1f%%", savingsRate * 100)) of your income",
            suggestion: savingsScore < 70 ? "Aim to save at least 15-20% of your income. Automate transfers on payday." : "Your savings rate is strong. Keep it up!"
        ))

        // 2. Emergency Fund (15% weight)
        let monthsCovered = monthlyIncome > 0 ? profile.currentSavings / (monthlyIncome * 0.7) : 0
        let emergencyScore = min(100, Int(monthsCovered / 6.0 * 100)) // 6 months = 100
        components.append(ScoreComponent(
            id: "emergency_fund",
            name: "Emergency Fund",
            score: emergencyScore,
            weight: 0.15,
            weighted: Double(emergencyScore) * 0.15,
            description: String(format: "%.1f months of expenses covered", monthsCovered),
            suggestion: emergencyScore < 70 ? "Build up 3-6 months of expenses in a high-interest savings account before investing aggressively." : "Your emergency fund is solid."
        ))

        // 3. TFSA Usage (15% weight)
        let tfsaMaxRoom = TaxCalculator.tfsaCumulativeRoom // Cumulative room since 2009 (through 2026)
        let tfsaUsageRate = tfsaMaxRoom > 0 ? profile.tfsaRoomUsed / tfsaMaxRoom : 0
        let tfsaScore = min(100, Int(tfsaUsageRate * 100))
        components.append(ScoreComponent(
            id: "tfsa_usage",
            name: "TFSA Usage",
            score: tfsaScore,
            weight: 0.15,
            weighted: Double(tfsaScore) * 0.15,
            description: String(format: "%.0f%% of available TFSA room used", tfsaUsageRate * 100),
            suggestion: tfsaScore < 50 ? "You have significant TFSA room unused. Every dollar inside grows completely tax-free." : "Good TFSA utilization."
        ))

        // 4. RRSP Usage (15% weight)
        let rrspRoom = min(income * 0.18, TaxCalculator.rrspMaxDeduction)
        let rrspUsageRate = rrspRoom > 0 ? min(profile.rrspRoomUsed / rrspRoom, 1.0) : 0
        let rrspScore = min(100, Int(rrspUsageRate * 100))
        components.append(ScoreComponent(
            id: "rrsp_usage",
            name: "RRSP Usage",
            score: rrspScore,
            weight: 0.15,
            weighted: Double(rrspScore) * 0.15,
            description: String(format: "%.0f%% of annual RRSP room used", rrspUsageRate * 100),
            suggestion: rrspScore < 50 ? "RRSP contributions reduce your taxable income. At your bracket, every $1,000 saves you significant taxes." : "Strong RRSP contribution habits."
        ))

        // 5. Investment Fees (10% weight) — based on risk tolerance as proxy
        let feeScore: Int
        switch profile.riskTolerance {
        case .growth: feeScore = 85  // Likely using ETFs
        case .balanced: feeScore = 65
        case .conservative: feeScore = 50  // More likely in high-fee products
        }
        components.append(ScoreComponent(
            id: "investment_fees",
            name: "Investment Fees",
            score: feeScore,
            weight: 0.10,
            weighted: Double(feeScore) * 0.10,
            description: profile.riskTolerance == .growth ? "Growth profile suggests low-cost investing" : "Consider reviewing your investment fees",
            suggestion: feeScore < 70 ? "Switch from mutual funds (2%+ MER) to index ETFs (0.2% MER). The fee difference compounds into hundreds of thousands over decades." : "Your fee structure appears reasonable."
        ))

        // 6. Diversification (10% weight) — based on whether using both RRSP and TFSA
        let usesBoth = profile.rrspRoomUsed > 0 && profile.tfsaRoomUsed > 0
        let diversificationScore = usesBoth ? 80 : (profile.rrspRoomUsed > 0 || profile.tfsaRoomUsed > 0 ? 50 : 10)
        components.append(ScoreComponent(
            id: "diversification",
            name: "Diversification",
            score: diversificationScore,
            weight: 0.10,
            weighted: Double(diversificationScore) * 0.10,
            description: usesBoth ? "Using both RRSP and TFSA accounts" : "Consider using multiple account types",
            suggestion: diversificationScore < 70 ? "Use the 1-2 Punch strategy: contribute to RRSP for the tax deduction, then invest the refund in your TFSA." : "Good account diversification."
        ))

        // 7. Debt Ratio (15% weight) — estimated from savings vs income
        let debtScore: Int
        let savingsToIncomeRatio = income > 0 ? profile.currentSavings / income : 0
        if savingsToIncomeRatio >= 1.0 { debtScore = 90 }
        else if savingsToIncomeRatio >= 0.5 { debtScore = 75 }
        else if savingsToIncomeRatio >= 0.25 { debtScore = 60 }
        else { debtScore = 40 }
        components.append(ScoreComponent(
            id: "debt_ratio",
            name: "Debt Ratio",
            score: debtScore,
            weight: 0.15,
            weighted: Double(debtScore) * 0.15,
            description: String(format: "Savings-to-income ratio: %.1fx", savingsToIncomeRatio),
            suggestion: debtScore < 60 ? "Focus on building savings before increasing investments. Pay off high-interest debt first." : "Your savings-to-income ratio is healthy."
        ))

        // Calculate total weighted score
        let totalWeighted = components.reduce(0.0) { $0 + $1.weighted }
        let totalScore = min(100, Int(totalWeighted))
        let grade = Grade.from(score: totalScore)

        // Generate top recommendations (from lowest-scoring components)
        let sortedByScore = components.sorted { $0.score < $1.score }
        let recommendations = sortedByScore.prefix(3).map(\.suggestion)

        return ScoreResult(
            totalScore: totalScore,
            breakdown: components,
            grade: grade,
            recommendations: recommendations
        )
    }
}

import Foundation

struct FinancialProfile: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var age: Int
    var retirementAge: Int
    var province: String
    var incomeBracket: String
    var rrspRoomUsed: Double
    var tfsaRoomUsed: Double
    var currentSavings: Double
    var monthlyContribution: Double
    var riskTolerance: RiskTolerance
    var updatedAt: Date?

    /// Province as enum, falling back to Ontario
    var provinceEnum: Province {
        Province(rawValue: province) ?? .on
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case age
        case retirementAge = "retirement_age"
        case province
        case incomeBracket = "income_bracket"
        case rrspRoomUsed = "rrsp_room_used"
        case tfsaRoomUsed = "tfsa_room_used"
        case currentSavings = "current_savings"
        case monthlyContribution = "monthly_contribution"
        case riskTolerance = "risk_tolerance"
        case updatedAt = "updated_at"
    }
}

enum RiskTolerance: String, Codable, CaseIterable {
    case conservative
    case balanced
    case growth

    var displayName: String {
        switch self {
        case .conservative: return "Conservative"
        case .balanced: return "Balanced"
        case .growth: return "Growth"
        }
    }

    var description: String {
        switch self {
        case .conservative: return "Lower risk, steady returns. Bonds and GICs."
        case .balanced: return "Mix of growth and stability. ETFs and balanced funds."
        case .growth: return "Higher risk, higher potential returns. Equity-heavy."
        }
    }

    var expectedReturn: Double {
        switch self {
        case .conservative: return 0.04
        case .balanced: return 0.06
        case .growth: return 0.08
        }
    }
}

enum IncomeBracket: String, CaseIterable {
    case under50k = "0-50000"
    case fiftyTo75k = "50000-75000"
    case seventyFiveTo100k = "75000-100000"
    case hundredTo130k = "100000-130000"
    case hundredThirtyTo160k = "130000-160000"
    case over160k = "160000+"

    var displayName: String {
        switch self {
        case .under50k: return "Under $50,000"
        case .fiftyTo75k: return "$50,000 – $75,000"
        case .seventyFiveTo100k: return "$75,000 – $100,000"
        case .hundredTo130k: return "$100,000 – $130,000"
        case .hundredThirtyTo160k: return "$130,000 – $160,000"
        case .over160k: return "$160,000+"
        }
    }

    var midpoint: Double {
        switch self {
        case .under50k: return 35_000
        case .fiftyTo75k: return 62_500
        case .seventyFiveTo100k: return 87_500
        case .hundredTo130k: return 115_000
        case .hundredThirtyTo160k: return 145_000
        case .over160k: return 200_000
        }
    }
}

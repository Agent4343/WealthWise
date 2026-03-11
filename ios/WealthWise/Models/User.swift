import Foundation

// MARK: - User

struct AppUser: Codable, Identifiable {
    let id: String
    let email: String
    let subscriptionTier: SubscriptionTier
    let subscriptionExpiresAt: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case subscriptionTier = "subscription_tier"
        case subscriptionExpiresAt = "subscription_expires_at"
        case createdAt = "created_at"
    }
}

// MARK: - Subscription Tier

enum SubscriptionTier: String, Codable, CaseIterable {
    case free
    case basic
    case premium

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .basic: return "Basic"
        case .premium: return "Premium"
        }
    }

    var canAccessDashboard: Bool { self == .basic || self == .premium }
    var canAccessPlanner: Bool { self == .basic || self == .premium }
    var canAccessWeeklyBriefs: Bool { self == .premium }
    var canSaveCalculations: Bool { self == .basic || self == .premium }
}

// MARK: - Financial Profile

struct FinancialProfile: Codable, Identifiable {
    let id: String
    let userId: String
    var currentAge: Int?
    var targetRetirementAge: Int?
    var province: CanadianProvince?
    var incomeBracket: String?
    var tfsaRoomUsed: Double?
    var rrspRoomAvailable: Double?
    var currentSavingsBalance: Double?
    var currentRrspBalance: Double?
    var currentTfsaBalance: Double?
    var monthlySavingsAmount: Double?
    var monthlySavingsTarget: Double?
    var riskTolerance: RiskTolerance?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case currentAge = "current_age"
        case targetRetirementAge = "target_retirement_age"
        case province
        case incomeBracket = "income_bracket"
        case tfsaRoomUsed = "tfsa_room_used"
        case rrspRoomAvailable = "rrsp_room_available"
        case currentSavingsBalance = "current_savings_balance"
        case currentRrspBalance = "current_rrsp_balance"
        case currentTfsaBalance = "current_tfsa_balance"
        case monthlySavingsAmount = "monthly_savings_amount"
        case monthlySavingsTarget = "monthly_savings_target"
        case riskTolerance = "risk_tolerance"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var yearsToRetirement: Int? {
        guard let age = currentAge, let retirementAge = targetRetirementAge else { return nil }
        return max(0, retirementAge - age)
    }
}

// MARK: - Risk Tolerance

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
        case .conservative: return "Capital preservation — GICs, bonds, minimal equities"
        case .balanced: return "Moderate growth — 60/40 equity/bond mix"
        case .growth: return "Long-term growth — 80%+ equities, index funds"
        }
    }
}

// MARK: - Canadian Provinces

enum CanadianProvince: String, Codable, CaseIterable {
    case ab = "AB"
    case bc = "BC"
    case mb = "MB"
    case nb = "NB"
    case nl = "NL"
    case ns = "NS"
    case nt = "NT"
    case nu = "NU"
    case on = "ON"
    case pe = "PE"
    case qc = "QC"
    case sk = "SK"
    case yt = "YT"

    var displayName: String {
        switch self {
        case .ab: return "Alberta"
        case .bc: return "British Columbia"
        case .mb: return "Manitoba"
        case .nb: return "New Brunswick"
        case .nl: return "Newfoundland & Labrador"
        case .ns: return "Nova Scotia"
        case .nt: return "Northwest Territories"
        case .nu: return "Nunavut"
        case .on: return "Ontario"
        case .pe: return "Prince Edward Island"
        case .qc: return "Québec"
        case .sk: return "Saskatchewan"
        case .yt: return "Yukon"
        }
    }
}

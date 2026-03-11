import Foundation

struct UserSubscription: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var tier: SubscriptionTier
    var appleOriginalTransactionId: String?
    var appleProductId: String?
    var status: SubscriptionStatus
    var expiresAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case tier
        case appleOriginalTransactionId = "apple_original_transaction_id"
        case appleProductId = "apple_product_id"
        case status
        case expiresAt = "expires_at"
        case updatedAt = "updated_at"
    }
}

enum SubscriptionTier: String, Codable, Comparable {
    case free
    case basic
    case premium

    static func < (lhs: SubscriptionTier, rhs: SubscriptionTier) -> Bool {
        let order: [SubscriptionTier] = [.free, .basic, .premium]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else { return false }
        return lhsIndex < rhsIndex
    }

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .basic: return "Basic"
        case .premium: return "Premium"
        }
    }
}

enum SubscriptionStatus: String, Codable {
    case active
    case expired
    case cancelled
    case gracePeriod = "grace_period"
}

enum StoreKitProductID: String, CaseIterable {
    case basicMonthly = "com.themileschool.wealthwise.basic.monthly"
    case basicAnnual = "com.themileschool.wealthwise.basic.annual"
    case premiumMonthly = "com.themileschool.wealthwise.premium.monthly"
    case premiumAnnual = "com.themileschool.wealthwise.premium.annual"
    case lifetime = "com.themileschool.wealthwise.lifetime"

    var tier: SubscriptionTier {
        switch self {
        case .basicMonthly, .basicAnnual: return .basic
        case .premiumMonthly, .premiumAnnual, .lifetime: return .premium
        }
    }

    var isAnnual: Bool {
        switch self {
        case .basicAnnual, .premiumAnnual: return true
        default: return false
        }
    }

    var isLifetime: Bool {
        self == .lifetime
    }

    static var allProductIDs: Set<String> {
        Set(allCases.map(\.rawValue))
    }
}

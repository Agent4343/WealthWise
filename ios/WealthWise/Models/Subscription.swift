import Foundation
import StoreKit

// MARK: - Subscription Product

struct SubscriptionProduct: Identifiable {
    let id: String
    let displayName: String
    let description: String
    let price: Decimal
    let displayPrice: String
    let tier: SubscriptionTier
    let billingPeriod: BillingPeriod
    let product: Product   // StoreKit 2 Product

    enum BillingPeriod {
        case monthly
        case annual

        var displayName: String {
            switch self {
            case .monthly: return "month"
            case .annual: return "year"
            }
        }
    }
}

// MARK: - StoreKit Product IDs

enum StoreKitProductID: String, CaseIterable {
    case basicMonthly   = "com.wealthwise.basic.monthly"
    case basicAnnual    = "com.wealthwise.basic.annual"
    case premiumMonthly = "com.wealthwise.premium.monthly"
    case premiumAnnual  = "com.wealthwise.premium.annual"

    var tier: SubscriptionTier {
        switch self {
        case .basicMonthly, .basicAnnual: return .basic
        case .premiumMonthly, .premiumAnnual: return .premium
        }
    }

    var billingPeriod: SubscriptionProduct.BillingPeriod {
        switch self {
        case .basicMonthly, .premiumMonthly: return .monthly
        case .basicAnnual, .premiumAnnual: return .annual
        }
    }
}

// MARK: - Purchase Result

enum PurchaseResult {
    case success(SubscriptionTier)
    case cancelled
    case pending
    case failed(Error)
}

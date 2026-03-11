import Foundation
import StoreKit

// MARK: - Subscription ViewModel

@MainActor
final class SubscriptionViewModel: ObservableObject {
    @Published var products: [SubscriptionProduct] = []
    @Published var isLoading: Bool = false
    @Published var purchaseState: PurchaseState = .idle
    @Published var errorMessage: String?

    enum PurchaseState {
        case idle
        case purchasing
        case success(SubscriptionTier)
        case failed(String)
        case cancelled
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let productIDs = StoreKitProductID.allCases.map(\.rawValue)
            let skProducts = try await Product.products(for: productIDs)

            products = skProducts.compactMap { product in
                guard let id = StoreKitProductID(rawValue: product.id) else { return nil }
                return SubscriptionProduct(
                    id: product.id,
                    displayName: product.displayName,
                    description: product.description,
                    price: product.price,
                    displayPrice: product.displayPrice,
                    tier: id.tier,
                    billingPeriod: id.billingPeriod,
                    product: product
                )
            }.sorted { $0.price < $1.price }

        } catch {
            errorMessage = "Failed to load subscription options: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase

    func purchase(_ subscriptionProduct: SubscriptionProduct) async {
        purchaseState = .purchasing

        do {
            let result = try await subscriptionProduct.product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                purchaseState = .success(subscriptionProduct.tier)

            case .userCancelled:
                purchaseState = .cancelled

            case .pending:
                purchaseState = .idle

            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    // MARK: - StoreKit Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}

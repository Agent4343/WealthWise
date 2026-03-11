import Foundation
import StoreKit
import SwiftUI

@MainActor
final class SubscriptionViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var currentTier: SubscriptionTier = .free
    @Published var isLoading = false
    @Published var showPaywall = false
    @Published var purchaseError: String?

    private var transactionListener: Task<Void, Error>?

    init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await refreshEntitlement()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    var basicMonthly: Product? {
        products.first { $0.id == StoreKitProductID.basicMonthly.rawValue }
    }

    var basicAnnual: Product? {
        products.first { $0.id == StoreKitProductID.basicAnnual.rawValue }
    }

    var premiumMonthly: Product? {
        products.first { $0.id == StoreKitProductID.premiumMonthly.rawValue }
    }

    var premiumAnnual: Product? {
        products.first { $0.id == StoreKitProductID.premiumAnnual.rawValue }
    }

    var lifetime: Product? {
        products.first { $0.id == StoreKitProductID.lifetime.rawValue }
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: StoreKitProductID.allProductIDs)
                .sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlement()

            case .userCancelled:
                break

            case .pending:
                break

            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        try? await AppStore.sync()
        await refreshEntitlement()
    }

    func refreshEntitlement() async {
        var highestTier: SubscriptionTier = .free

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if let productID = StoreKitProductID(rawValue: transaction.productID) {
                    if productID.tier > highestTier {
                        highestTier = productID.tier
                    }
                }
            }
        }

        currentTier = highestTier

        // Also sync with server
        do {
            let serverSub = try await APIService.shared.fetchSubscriptionStatus()
            if serverSub.tier > currentTier && serverSub.status == .active {
                currentTier = serverSub.tier
            }
        } catch {
            // Server unavailable — use local entitlement
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if let transaction = try? self.checkVerified(result) {
                    await transaction.finish()
                    await self.refreshEntitlement()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}

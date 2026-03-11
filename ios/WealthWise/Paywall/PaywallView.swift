import SwiftUI
import StoreKit

// MARK: - Paywall View

struct PaywallView: View {
    let requiredTier: SubscriptionTier
    @StateObject private var viewModel = SubscriptionViewModel()
    @State private var selectedPeriod: SubscriptionProduct.BillingPeriod = .monthly
    @Environment(\.dismiss) private var dismiss

    var filteredProducts: [SubscriptionProduct] {
        viewModel.products.filter { $0.billingPeriod == selectedPeriod }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    paywallHeader

                    // Billing Period Toggle
                    Picker("Billing Period", selection: $selectedPeriod) {
                        Text("Monthly").tag(SubscriptionProduct.BillingPeriod.monthly)
                        Text("Annual (Save 33%)").tag(SubscriptionProduct.BillingPeriod.annual)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Subscription Cards
                    VStack(spacing: 16) {
                        ForEach(filteredProducts) { product in
                            SubscriptionCard(
                                product: product,
                                isRecommended: product.tier == .premium,
                                isLoading: viewModel.purchaseState == .purchasing,
                                onPurchase: {
                                    Task { await viewModel.purchase(product) }
                                }
                            )
                        }

                        if viewModel.isLoading {
                            ProgressView("Loading subscription options...")
                        }
                    }
                    .padding(.horizontal)

                    // Feature comparison
                    FeatureComparisonTable()

                    // Footer
                    VStack(spacing: 8) {
                        Button("Restore Purchases") {
                            Task { await viewModel.restorePurchases() }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        Text("Subscriptions auto-renew. Cancel anytime in Settings > Apple ID. Prices in CAD.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.bottom, 32)
                }
                .padding(.top)
            }
            .navigationTitle("Upgrade WealthWise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await viewModel.loadProducts() }
            .onChange(of: viewModel.purchaseState) { _, newState in
                if case .success = newState { dismiss() }
            }
            .alert("Purchase Failed", isPresented: .constant({
                if case .failed = viewModel.purchaseState { return true }
                return false
            }())) {
                Button("OK") { viewModel.purchaseState = .idle }
            } message: {
                if case .failed(let msg) = viewModel.purchaseState {
                    Text(msg)
                }
            }
        }
    }

    private var paywallHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow)

            Text("Unlock WealthWise")
                .font(.largeTitle.bold())

            Text(requiredTier == .premium
                 ? "Get your personalized Monday Morning Brief every week — the financial guidance Canada never gave you."
                 : "Access all 7 chapters, all 5 calculators, and your personal financial dashboard.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

// MARK: - Subscription Card

struct SubscriptionCard: View {
    let product: SubscriptionProduct
    let isRecommended: Bool
    let isLoading: Bool
    let onPurchase: () -> Void

    private var tierFeatures: [String] {
        switch product.tier {
        case .basic:
            return [
                "All 7 School chapters",
                "5 financial calculators",
                "Personal dashboard",
                "RRSP + TFSA tracker",
                "Goal tracking",
            ]
        case .premium:
            return [
                "Everything in Basic",
                "Monday AI Weekly Brief",
                "Personalized to your profile",
                "Bank of Canada rate context",
                "Market commentary",
                "RRSP/TFSA action items",
            ]
        case .free:
            return []
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(product.tier.displayName)
                            .font(.headline)
                        if isRecommended {
                            Text("MOST POPULAR")
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    Text("\(product.displayPrice) / \(product.billingPeriod.displayName)")
                        .font(.title2.bold())
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(tierFeatures, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.subheadline)
                        Text(feature)
                            .font(.subheadline)
                    }
                }
            }

            Button(action: onPurchase) {
                Group {
                    if isLoading {
                        ProgressView().progressViewStyle(.circular).tint(.white)
                    } else {
                        Text("Subscribe — \(product.displayPrice)/\(product.billingPeriod.displayName)")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(isRecommended ? .blue : .secondary)
            .disabled(isLoading)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isRecommended ? Color.blue : Color.gray.opacity(0.2), lineWidth: isRecommended ? 2 : 1)
        )
        .shadow(color: isRecommended ? .blue.opacity(0.15) : .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Feature Comparison Table

struct FeatureComparisonTable: View {
    private let features: [(String, Bool, Bool)] = [
        ("Chapters 1–3 (Free)", true, true),
        ("All 7 School Chapters", false, true),
        ("5 Financial Calculators", false, true),
        ("Personal Dashboard", false, true),
        ("RRSP + TFSA Tracker", false, true),
        ("Monday AI Weekly Brief", false, false),
        ("Personalized Market Context", false, false),
        ("RRSP/TFSA Action Items", false, false),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Feature Comparison")
                .font(.headline)
                .padding()

            HStack {
                Spacer()
                Text("Basic").font(.caption.bold()).frame(width: 60)
                Text("Premium").font(.caption.bold()).foregroundStyle(.blue).frame(width: 70)
            }
            .padding(.horizontal)

            ForEach(features, id: \.0) { feature, basic, premium in
                HStack {
                    Text(feature).font(.subheadline)
                    Spacer()
                    Image(systemName: basic ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundStyle(basic ? .green : .secondary)
                        .frame(width: 60)
                    Image(systemName: premium ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundStyle(premium ? .green : .secondary)
                        .frame(width: 70)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                Divider().padding(.horizontal)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .padding(.horizontal)
    }
}

#Preview {
    PaywallView(requiredTier: .basic)
}

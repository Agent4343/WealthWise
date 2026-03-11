import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var subscriptionVM: SubscriptionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.accent)

                        Text("Unlock WealthWise")
                            .font(.title.bold())

                        Text("The financial education app Canada never had")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)

                    // Tier selector
                    Picker("Plan", selection: $selectedTab) {
                        Text("Basic").tag(0)
                        Text("Premium").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if selectedTab == 0 {
                        basicPlan
                    } else {
                        premiumPlan
                    }

                    // Restore
                    Button("Restore Purchases") {
                        Task { await subscriptionVM.restorePurchases() }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    // Legal links
                    HStack(spacing: 16) {
                        Link("Terms", destination: Configuration.termsOfServiceURL)
                        Link("Privacy", destination: Configuration.privacyPolicyURL)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .alert("Purchase Error", isPresented: .constant(subscriptionVM.purchaseError != nil)) {
                Button("OK") { subscriptionVM.purchaseError = nil }
            } message: {
                Text(subscriptionVM.purchaseError ?? "")
            }
        }
    }

    private var basicPlan: some View {
        VStack(spacing: 16) {
            // Features
            VStack(alignment: .leading, spacing: 10) {
                featureRow("All 7 School chapters")
                featureRow("5 financial calculators with save")
                featureRow("Personal financial dashboard")
                featureRow("RRSP + TFSA contribution tracker")
                featureRow("Goal setting and progress tracking")
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Monthly
            if let product = subscriptionVM.basicMonthly {
                purchaseButton(product: product, label: "Basic Monthly", price: product.displayPrice)
            }

            // Annual
            if let product = subscriptionVM.basicAnnual {
                purchaseButton(
                    product: product,
                    label: "Basic Annual — Save 33%",
                    price: "\(product.displayPrice)/year"
                )
            }
        }
    }

    private var premiumPlan: some View {
        VStack(spacing: 16) {
            // Badge
            Text("AI-POWERED")
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(.purple)
                .foregroundStyle(.white)
                .clipShape(Capsule())

            // Features
            VStack(alignment: .leading, spacing: 10) {
                featureRow("Everything in Basic")
                featureRow("Monday Morning Weekly Brief (AI)")
                featureRow("Personalized to your profile")
                featureRow("Bank of Canada rate context")
                featureRow("Market conditions & commentary")
                featureRow("RRSP/TFSA action recommendations")
                featureRow("Priority support")
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Monthly
            if let product = subscriptionVM.premiumMonthly {
                purchaseButton(product: product, label: "Premium Monthly", price: product.displayPrice)
            }

            // Annual
            if let product = subscriptionVM.premiumAnnual {
                purchaseButton(
                    product: product,
                    label: "Premium Annual — Save 33%",
                    price: "\(product.displayPrice)/year"
                )
            }
        }
    }

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.subheadline)
            Text(text)
                .font(.subheadline)
        }
    }

    private func purchaseButton(product: Product, label: String, price: String) -> some View {
        Button {
            Task { await subscriptionVM.purchase(product) }
        } label: {
            if subscriptionVM.isLoading {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            } else {
                VStack(spacing: 2) {
                    Text(label)
                        .fontWeight(.semibold)
                    Text(price)
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(subscriptionVM.isLoading)
    }
}

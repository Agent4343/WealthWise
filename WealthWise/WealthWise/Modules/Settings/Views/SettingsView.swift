import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var subscriptionVM: SubscriptionViewModel
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                // Account Section
                Section("Account") {
                    if let user = authManager.currentUser {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title)
                                .foregroundStyle(.accent)

                            VStack(alignment: .leading) {
                                Text(user.fullName ?? "WealthWise User")
                                    .font(.headline)
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    HStack {
                        Text("Subscription")
                        Spacer()
                        Text(subscriptionVM.currentTier.displayName)
                            .foregroundStyle(.secondary)
                    }

                    if subscriptionVM.currentTier == .free {
                        Button("Upgrade Plan") {
                            subscriptionVM.showPaywall = true
                        }
                    }
                }

                // App Section
                Section("App") {
                    NavigationLink {
                        DisclaimerView()
                    } label: {
                        Label("Disclaimer", systemImage: "exclamationmark.triangle")
                    }

                    Link(destination: Configuration.privacyPolicyURL) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }

                    Link(destination: Configuration.termsOfServiceURL) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                }

                // Support
                Section("Support") {
                    Link(destination: URL(string: "mailto:\(Configuration.supportEmail)")!) {
                        Label("Contact Support", systemImage: "envelope")
                    }

                    Button {
                        Task { await subscriptionVM.restorePurchases() }
                    } label: {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                    }
                }

                // Sign Out
                Section {
                    Button(role: .destructive) {
                        showSignOutConfirmation = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }

                // Version
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Sign Out?", isPresented: $showSignOutConfirmation) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await authManager.signOut()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

struct DisclaimerView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Important Disclaimer")
                    .font(.title2.bold())

                Text("""
                WealthWise is a financial education application developed by The Money School Inc. \
                The content provided in this app, including the AI-generated Weekly Brief, is for \
                educational and informational purposes only.

                WealthWise does NOT provide personalized financial, investment, or tax advice as \
                defined by IIROC, OSC, or provincial securities regulators. The information \
                presented should not be construed as a recommendation to buy, sell, or hold any \
                security or financial product.

                All calculations, projections, and illustrations are for educational purposes \
                only and are based on hypothetical scenarios. Actual results will vary based on \
                market conditions, individual circumstances, and other factors.

                Past performance does not guarantee future results. Investing involves risk, \
                including the potential loss of principal.

                Always consult with a qualified Certified Financial Planner (CFP), tax \
                professional, or registered investment advisor before making financial decisions \
                specific to your situation.

                WealthWise is not registered with IIROC, the OSC, or any provincial securities \
                regulator. We are not a portfolio manager, fund dealer, or exempt market dealer.

                Your use of this application is subject to our Terms of Service and Privacy Policy.
                """)
                .font(.subheadline)
                .lineSpacing(4)
            }
            .padding()
        }
        .navigationTitle("Disclaimer")
        .navigationBarTitleDisplayMode(.inline)
    }
}

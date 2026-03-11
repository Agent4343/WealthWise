import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject private var subscriptionVM: SubscriptionViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.profile == nil {
                    ProgressView("Loading your dashboard...")
                } else if let profile = viewModel.profile {
                    dashboardContent(profile: profile)
                } else {
                    emptyState
                }
            }
            .navigationTitle("Dashboard")
            .sheet(isPresented: $viewModel.showProfileSetup) {
                ProfileSetupView(viewModel: viewModel)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showProfileSetup = true
                    } label: {
                        Image(systemName: "pencil.circle")
                    }
                }
            }
            .task {
                await viewModel.loadProfile()
            }
        }
    }

    private func dashboardContent(profile: FinancialProfile) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Retirement Projection Card
                if let result = viewModel.projectedRetirement {
                    retirementCard(result: result, profile: profile)
                }

                // Account Tracker Cards
                HStack(spacing: 12) {
                    accountCard(
                        title: "TFSA Room",
                        used: profile.tfsaRoomUsed,
                        total: viewModel.tfsaMaxRoom,
                        color: .green
                    )

                    accountCard(
                        title: "RRSP Room",
                        used: profile.rrspRoomUsed,
                        total: viewModel.estimatedRrspRoom,
                        color: .blue
                    )
                }

                // Monthly Contribution
                contributionCard(profile: profile)

                // Quick Stats
                statsCard(profile: profile)
            }
            .padding()
        }
    }

    private func retirementCard(result: CompoundInterestCalculator.RetirementResult, profile: FinancialProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Retirement Projection", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline)
                Spacer()
                Text("Age \(profile.retirementAge)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(CurrencyFormatter.formatLarge(result.finalBalance))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.green)

            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Monthly Income")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.format(result.monthlyIncomeAt4Percent, compact: true))
                        .font(.subheadline.bold())
                }

                Divider().frame(height: 30)

                VStack(alignment: .leading) {
                    Text("Interest Earned")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.formatLarge(result.totalInterestEarned))
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                }

                Divider().frame(height: 30)

                VStack(alignment: .leading) {
                    Text("Contributed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.formatLarge(result.totalContributions))
                        .font(.subheadline.bold())
                }
            }

            Text("Based on \(CurrencyFormatter.formatPercent(profile.riskTolerance.expectedReturn)) avg annual return (\(profile.riskTolerance.displayName))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func accountCard(title: String, used: Double, total: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(CurrencyFormatter.format(max(0, total - used), compact: true))
                .font(.title3.bold())
                .foregroundStyle(color)

            Text("remaining")
                .font(.caption2)
                .foregroundStyle(.secondary)

            ProgressView(value: min(used / max(total, 1), 1))
                .tint(color)

            Text("\(CurrencyFormatter.format(used, compact: true)) used")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func contributionCard(profile: FinancialProfile) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Monthly Contribution")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(CurrencyFormatter.format(profile.monthlyContribution, compact: true))
                    .font(.title2.bold())
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Annual")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(CurrencyFormatter.format(profile.monthlyContribution * 12, compact: true))
                    .font(.title3.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statsCard(profile: FinancialProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Stats")
                .font(.headline)

            HStack {
                statItem(label: "Current Savings", value: CurrencyFormatter.formatLarge(profile.currentSavings))
                Divider().frame(height: 30)
                statItem(label: "Risk Profile", value: profile.riskTolerance.displayName)
                Divider().frame(height: 30)
                statItem(label: "Years to Retire", value: "\(max(0, profile.retirementAge - profile.age))")
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(.accent)

            Text("Set Up Your Profile")
                .font(.title2.bold())

            Text("Tell us about your financial situation and goals to unlock your personalized dashboard.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                viewModel.showProfileSetup = true
            } label: {
                Text("Get Started")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
        }
    }
}

import SwiftUI

// MARK: - Dashboard View

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.profile == nil {
                    ProgressView("Loading your dashboard...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let profile = viewModel.profile {
                    DashboardContentView(profile: profile, viewModel: viewModel)
                } else {
                    EmptyDashboardView(onSetup: { viewModel.showProfileSetup = true })
                }
            }
            .navigationTitle("Dashboard")
            .task { await viewModel.loadProfile() }
            .sheet(isPresented: $viewModel.showProfileSetup) {
                ProfileSetupView(viewModel: viewModel)
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

// MARK: - Dashboard Content

struct DashboardContentView: View {
    let profile: FinancialProfile
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Net Worth Card
                MetricCard(
                    title: "Estimated Net Worth",
                    value: CurrencyFormatter.formatCompact(viewModel.netWorth),
                    subtitle: "RRSP + TFSA + Other Savings",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                )

                // Account Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    AccountCard(
                        title: "RRSP",
                        balance: profile.currentRrspBalance ?? 0,
                        room: profile.rrspRoomAvailable,
                        icon: "building.columns.fill",
                        color: .indigo
                    )
                    AccountCard(
                        title: "TFSA",
                        balance: profile.currentTfsaBalance ?? 0,
                        room: viewModel.tfsaRoomRemaining,
                        icon: "sparkles",
                        color: .green
                    )
                }

                // Retirement Timeline
                if let age = profile.currentAge, let retAge = profile.targetRetirementAge {
                    RetirementTimelineCard(
                        currentAge: age,
                        retirementAge: retAge,
                        currentSavings: viewModel.netWorth,
                        monthlySavings: profile.monthlySavingsAmount ?? 0
                    )
                }

                // Savings Rate
                if let monthly = profile.monthlySavingsAmount, let target = profile.monthlySavingsTarget {
                    SavingsRateCard(monthly: monthly, target: target)
                }

                // Edit Profile Button
                Button(action: { viewModel.showProfileSetup = true }) {
                    Label("Update Financial Profile", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
            }
            .padding()
        }
    }
}

// MARK: - Supporting Cards

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title2.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}

struct AccountCard: View {
    let title: String
    let balance: Double
    let room: Double?
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
                Spacer()
            }

            Text(CurrencyFormatter.format(balance))
                .font(.title3.bold())

            if let room = room {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Room Available")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.format(room))
                        .font(.caption.bold())
                        .foregroundStyle(color)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}

struct RetirementTimelineCard: View {
    let currentAge: Int
    let retirementAge: Int
    let currentSavings: Double
    let monthlySavings: Double

    private var yearsToRetirement: Int { max(0, retirementAge - currentAge) }
    private var projectedValue: Double {
        CompoundInterestCalculator.futureValue(
            principal: currentSavings,
            monthlyContribution: monthlySavings,
            annualRate: 7.0,
            years: yearsToRetirement
        )
    }
    private var monthlyIncome: Double {
        CompoundInterestCalculator.monthlyWithdrawal(portfolioValue: projectedValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Retirement Projection", systemImage: "calendar")
                .font(.headline)

            HStack(spacing: 24) {
                VStack(alignment: .leading) {
                    Text("Years Away")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("\(yearsToRetirement)")
                        .font(.title2.bold())
                }
                VStack(alignment: .leading) {
                    Text("Projected at 65")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(CurrencyFormatter.formatCompact(projectedValue))
                        .font(.title2.bold())
                }
                VStack(alignment: .leading) {
                    Text("Monthly Income")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(CurrencyFormatter.format(monthlyIncome))
                        .font(.title3.bold())
                }
            }

            Text("Assuming 7% annual return, 4% withdrawal rate")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}

struct SavingsRateCard: View {
    let monthly: Double
    let target: Double
    private var rate: Double { min(1.0, monthly / target) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Monthly Savings Rate", systemImage: "arrow.up.circle")
                .font(.headline)

            ProgressView(value: rate)
                .tint(rate >= 1.0 ? .green : .blue)

            HStack {
                Text(CurrencyFormatter.format(monthly) + " / month")
                    .font(.subheadline.bold())
                Spacer()
                Text("Goal: \(CurrencyFormatter.format(target))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}

// MARK: - Empty State

struct EmptyDashboardView: View {
    let onSetup: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text("Set Up Your Dashboard")
                    .font(.title2.bold())
                Text("Enter your financial profile to see your personalized wealth snapshot.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button("Set Up Profile", action: onSetup)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthManager.shared)
}

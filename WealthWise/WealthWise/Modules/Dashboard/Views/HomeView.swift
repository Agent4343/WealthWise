import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject private var subscriptionVM: SubscriptionViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.profile == nil {
                    ProgressView("Loading...")
                } else if let profile = viewModel.profile {
                    homeContent(profile: profile)
                } else {
                    emptyState
                }
            }
            .navigationTitle("WealthWise")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showProfileSetup = true
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showProfileSetup) {
                ProfileSetupView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadProfile()
            }
        }
    }

    private func homeContent(profile: FinancialProfile) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Money Score Card
                let scoreResult = MoneyScoreCalculator.calculate(profile: profile)
                NavigationLink {
                    MoneyScoreView(scoreResult: scoreResult)
                } label: {
                    moneyScoreCard(scoreResult: scoreResult)
                }
                .buttonStyle(.plain)

                // Retirement Projection Card
                if let result = viewModel.projectedRetirement {
                    retirementProjectionCard(result: result, profile: profile)
                }

                // Progress Bar toward retirement goal
                if let result = viewModel.projectedRetirement {
                    progressCard(profile: profile, projectedBalance: result.finalBalance)
                }

                // Weekly Action Item (Premium) / Brief upsell (Free/Pro)
                if subscriptionVM.currentTier >= .premium {
                    weeklyActionCard
                } else {
                    briefUpsellCard
                }

                // Quick Actions
                quickActionsGrid
            }
            .padding()
        }
    }

    private func moneyScoreCard(scoreResult: MoneyScoreCalculator.ScoreResult) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: Double(scoreResult.totalScore) / 100.0)
                    .stroke(scoreColor(scoreResult.totalScore), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text("\(scoreResult.totalScore)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor(scoreResult.totalScore))
            }
            .frame(width: 70, height: 70)

            VStack(alignment: .leading, spacing: 4) {
                Text("Money Score")
                    .font(.headline)

                Text(scoreResult.grade.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(scoreColor(scoreResult.totalScore))

                if let topRec = scoreResult.recommendations.first {
                    Text(topRec)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func retirementProjectionCard(result: CompoundInterestCalculator.RetirementResult, profile: FinancialProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Retirement Projection", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.subheadline.bold())
                Spacer()
                Text("Age \(profile.retirementAge)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(CurrencyFormatter.formatLarge(result.finalBalance))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.green)

            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Monthly Income")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.format(result.monthlyIncomeAt4Percent, compact: true))
                        .font(.caption.bold())
                }
                Divider().frame(height: 24)
                VStack(alignment: .leading) {
                    Text("Interest Earned")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.formatLarge(result.totalInterestEarned))
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func progressCard(profile: FinancialProfile, projectedBalance: Double) -> some View {
        let progress = projectedBalance > 0 ? min(profile.currentSavings / projectedBalance, 1.0) : 0

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Retirement Progress")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.subheadline.bold())
                    .foregroundStyle(.accent)
            }

            ProgressView(value: progress)
                .tint(.accent)

            HStack {
                Text(CurrencyFormatter.formatLarge(profile.currentSavings))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(CurrencyFormatter.formatLarge(projectedBalance))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var weeklyActionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.teal)
                Text("Weekly Action Item")
                    .font(.subheadline.bold())
            }

            Text("Check your TFSA contribution room on CRA My Account and set up an automatic monthly transfer.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .background(Color.teal.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var briefUpsellCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "newspaper.fill")
                    .foregroundStyle(.purple)
                Text("AI Weekly Brief")
                    .font(.subheadline.bold())
                Spacer()
                Text("Premium")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.purple.opacity(0.15))
                    .foregroundStyle(.purple)
                    .clipShape(Capsule())
            }

            Text("Every Monday: a personalized action plan built from your numbers. RRSP deadlines, tax-saving moves, and exactly what to do.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(3)

            Button {
                subscriptionVM.showPaywall = true
            } label: {
                Text("Start Free Trial")
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var quickActionsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            quickActionButton(icon: "function", title: "Calculator", color: .blue) {
                NotificationCenter.default.post(name: .navigateToTab, object: nil, userInfo: ["tab": 2])
            }
            quickActionButton(icon: "book.fill", title: "Learn", color: .purple) {
                NotificationCenter.default.post(name: .navigateToTab, object: nil, userInfo: ["tab": 1])
            }
            quickActionButton(icon: "newspaper.fill", title: "Brief", color: .orange) {
                NotificationCenter.default.post(name: .navigateToTab, object: nil, userInfo: ["tab": 3])
            }
            quickActionButton(icon: "gearshape.fill", title: "Settings", color: .gray) {
                NotificationCenter.default.post(name: .navigateToTab, object: nil, userInfo: ["tab": 4])
            }
        }
    }

    private func quickActionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(.accent)

            Text("Set Up Your Profile")
                .font(.title2.bold())

            Text("Enter your financial details to see your Money Score, retirement projection, and personalized insights.")
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

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }
}

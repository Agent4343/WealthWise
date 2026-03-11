import SwiftUI

struct BriefListView: View {
    @StateObject private var viewModel = BriefViewModel()
    @EnvironmentObject private var subscriptionVM: SubscriptionViewModel

    var body: some View {
        NavigationStack {
            Group {
                if subscriptionVM.currentTier < .premium {
                    premiumRequired
                } else if viewModel.isLoading && viewModel.briefs.isEmpty {
                    ProgressView("Loading your briefs...")
                } else if viewModel.briefs.isEmpty {
                    emptyState
                } else {
                    briefList
                }
            }
            .navigationTitle("Weekly Briefs")
            .task {
                if subscriptionVM.currentTier >= .premium {
                    await viewModel.loadBriefs()
                }
            }
        }
    }

    private var briefList: some View {
        List {
            ForEach(viewModel.briefs) { brief in
                NavigationLink {
                    BriefDetailView(brief: brief)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(brief.formattedWeekOf)
                            .font(.headline)

                        Text(brief.sectionOneSnapshot)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)

                        if let delivered = brief.deliveredAt {
                            Text("Delivered \(delivered, style: .relative) ago")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            if viewModel.hasMorePages {
                Button("Load More") {
                    Task { await viewModel.loadMore() }
                }
            }
        }
        .refreshable {
            await viewModel.loadBriefs()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "newspaper")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Briefs Yet")
                .font(.title2.bold())

            Text("Your first Weekly Brief will arrive on Monday morning. Check back then!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var premiumRequired: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 64))
                .foregroundStyle(.purple)

            Text("AI Weekly Briefs")
                .font(.title2.bold())

            Text("Every Monday morning, get a personalized financial briefing based on your profile, current market conditions, and Bank of Canada decisions.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 12) {
                briefFeature(icon: "eye", text: "Your Week at a Glance")
                briefFeature(icon: "chart.bar", text: "Canadian Economic Pulse")
                briefFeature(icon: "building.columns", text: "RRSP & TFSA Guidance")
                briefFeature(icon: "lightbulb", text: "What to Think About")
                briefFeature(icon: "checkmark.circle", text: "Your Monday Action Item")
            }
            .padding()

            Button {
                subscriptionVM.showPaywall = true
            } label: {
                Text("Upgrade to Premium — $24.99/mo")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .padding(.horizontal, 24)
        }
    }

    private func briefFeature(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.purple)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}

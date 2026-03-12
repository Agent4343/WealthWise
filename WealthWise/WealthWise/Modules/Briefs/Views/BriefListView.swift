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
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 64))
                    .foregroundStyle(.purple)

                Text("Your AI Financial Coach")
                    .font(.title2.bold())

                Text("Every Monday at 7 AM, get a personalized action plan built from YOUR income, province, RRSP room, and TFSA balance.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                // Value proposition
                VStack(alignment: .leading, spacing: 14) {
                    briefFeature(icon: "eye.fill", text: "Week at a Glance — your score & bracket")
                    briefFeature(icon: "chart.bar.fill", text: "Canadian Economic Pulse — rates & markets")
                    briefFeature(icon: "building.columns.fill", text: "Account tracker — RRSP/TFSA room updates")
                    briefFeature(icon: "lightbulb.fill", text: "Tax-saving moves personalized to your bracket")
                    briefFeature(icon: "checkmark.circle.fill", text: "One clear action item every Monday")
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)

                // Cost comparison
                VStack(spacing: 8) {
                    HStack {
                        Text("Financial advisor")
                        Spacer()
                        Text("$2,000+/year")
                            .foregroundStyle(.red)
                    }
                    .font(.subheadline)

                    Divider()

                    HStack {
                        Text("WealthWise Premium")
                        Spacer()
                        Text("$9.99/month")
                            .foregroundStyle(.green)
                            .fontWeight(.bold)
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)

                Text("The average user saves $2,400+/year from RRSP tips alone.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    subscriptionVM.showPaywall = true
                } label: {
                    Text("Start 7-Day Free Trial")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .padding(.horizontal, 24)

                Text("Cancel anytime. No contracts.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 20)
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

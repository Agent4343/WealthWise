import SwiftUI

// MARK: - Briefs List View

struct BriefsListView: View {
    @StateObject private var viewModel = BriefsViewModel()
    @State private var selectedBriefId: String?
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && !viewModel.hasLoadedOnce {
                    ProgressView("Loading your briefs...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.briefs.isEmpty && viewModel.hasLoadedOnce {
                    EmptyBriefsView()
                } else {
                    briefsList
                }
            }
            .navigationTitle("Monday Briefs")
            .task { await viewModel.loadBriefs() }
            .refreshable { await viewModel.loadBriefs(refresh: true) }
            .navigationDestination(item: $selectedBriefId, destination: briefDetail)
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var briefsList: some View {
        List {
            ForEach(viewModel.briefs) { brief in
                BriefRowView(brief: brief)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedBriefId = brief.id }
                    .onAppear {
                        // Load next page when last item appears
                        if brief.id == viewModel.briefs.last?.id {
                            Task { await viewModel.loadNextPage() }
                        }
                    }
            }

            if viewModel.isLoading && viewModel.hasLoadedOnce {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private func briefDetail(id: String) -> some View {
        BriefDetailView(briefId: id, viewModel: viewModel)
    }
}

// MARK: - Brief Row

struct BriefRowView: View {
    let brief: WeeklyBriefListItem

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: brief.generatedAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(formattedDate, systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Text(brief.title)
                .font(.headline)

            if let snippet = brief.summarySnippet {
                Text(snippet)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Brief Detail View

struct BriefDetailView: View {
    let briefId: String
    @ObservedObject var viewModel: BriefsViewModel

    var body: some View {
        Group {
            if viewModel.isLoadingDetail {
                ProgressView("Loading brief...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let brief = viewModel.selectedBrief {
                BriefContentView(brief: brief)
            } else {
                Text("Unable to load brief.")
                    .foregroundStyle(.secondary)
            }
        }
        .task { await viewModel.loadBriefDetail(id: briefId) }
        .navigationTitle("Monday Brief")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Brief Content

struct BriefContentView: View {
    let brief: WeeklyBrief

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(brief.title)
                        .font(.title2.bold())
                    Text(brief.weekStartDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                // Section 1: Week at a Glance
                BriefSectionCard(
                    badge: "Week at a Glance",
                    content: brief.weekAtAGlance,
                    color: .blue
                )

                // Section 2: Canadian Economic Pulse
                BriefSectionCard(
                    title: "🇨🇦 Canadian Economic Pulse",
                    content: brief.canadianEconomicPulse,
                    color: .indigo
                )

                // Section 3: Your Accounts This Week
                BriefSectionCard(
                    title: "📊 Your Accounts This Week",
                    content: brief.accountsThisWeek,
                    color: .green
                )

                // Section 4: What to Think About
                BriefSectionCard(
                    title: "💡 What to Think About",
                    content: brief.whatToThinkAbout,
                    color: .orange
                )

                // Section 5: Monday Action Item (highlighted)
                VStack(alignment: .leading, spacing: 12) {
                    Label("Your Monday Action Item", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(brief.mondayActionItem)
                        .font(.body)
                        .foregroundStyle(.white)
                }
                .padding(20)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                // Disclaimer
                Text(brief.disclaimer)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 32)
            }
            .padding(.vertical)
        }
    }
}

struct BriefSectionCard: View {
    var badge: String? = nil
    var title: String? = nil
    let content: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let badge = badge {
                Text(badge)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.15))
                    .foregroundStyle(color)
                    .clipShape(Capsule())
            }
            if let title = title {
                Text(title)
                    .font(.headline)
            }
            Text(content)
                .font(.body)
                .lineSpacing(4)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Empty State

struct EmptyBriefsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text("Your First Brief Is Coming")
                    .font(.title2.bold())
                Text("Every Monday morning, your personalized WealthWise brief will appear here. Your first brief is generated the coming Sunday night.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    BriefsListView()
}

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            title: "Understand Your Financial Future",
            description: "Learn what 13 years of education never taught you — compound interest, TFSAs, RRSPs, and how Canadians actually build wealth.",
            color: Color(red: 0.08, green: 0.15, blue: 0.30)
        ),
        OnboardingPage(
            icon: "gauge.with.needle.fill",
            title: "Improve Your Financial Score",
            description: "Get a personalized Money Score, track your savings progress, and see exactly where you stand with your RRSP and TFSA goals.",
            color: Color(red: 0.12, green: 0.44, blue: 0.35)
        ),
        OnboardingPage(
            icon: "brain.head.profile",
            title: "Get Weekly Financial Insights",
            description: "Every Monday morning, receive an AI-powered briefing personalized to your profile — with Bank of Canada context and actionable recommendations.",
            color: .purple
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: 24) {
                        Spacer()

                        Image(systemName: page.icon)
                            .font(.system(size: 80))
                            .foregroundStyle(page.color)

                        Text(page.title)
                            .font(.title.bold())
                            .multilineTextAlignment(.center)

                        Text(page.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Spacer()
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            // Bottom button
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    hasCompletedOnboarding = true
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            if currentPage < pages.count - 1 {
                Button("Skip") {
                    hasCompletedOnboarding = true
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 24)
            } else {
                Color.clear.frame(height: 48)
            }
        }
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

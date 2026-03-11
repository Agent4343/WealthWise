import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "book.closed.fill",
            title: "The School Canada Forgot",
            description: "Learn what 13 years of education never taught you about money — compound interest, TFSAs, RRSPs, and how to actually build wealth.",
            color: .blue
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            title: "Your Financial Dashboard",
            description: "Track your RRSP room, TFSA contributions, and savings goals — all in one place. See exactly where you stand.",
            color: .green
        ),
        OnboardingPage(
            icon: "brain.head.profile",
            title: "AI-Powered Weekly Guidance",
            description: "Every Monday morning, get a personalized financial briefing based on your profile, current markets, and Bank of Canada decisions.",
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

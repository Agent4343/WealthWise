import SwiftUI

// MARK: - Onboarding Flow

struct OnboardingView: View {
    @State private var currentPage = 0
    var onComplete: () -> Void

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            emoji: "🏦",
            title: "Canada's Financial Education Gap",
            body: "13 years of school. Zero lessons on TFSAs, RRSPs, or compound interest. WealthWise fixes that in 15 minutes.",
            background: Color(red: 0.11, green: 0.21, blue: 0.34)
        ),
        OnboardingPage(
            emoji: "📊",
            title: "Your Personal Money Dashboard",
            body: "Track your RRSP room, TFSA balance, net worth, and savings rate. All in one place — connected to your goals.",
            background: Color(red: 0.27, green: 0.48, blue: 0.62)
        ),
        OnboardingPage(
            emoji: "🤖",
            title: "AI-Powered Monday Briefs",
            body: "Every Monday morning, your personalized financial briefing is ready. Current Bank of Canada rates, your accounts, one action to take.",
            background: Color(red: 0.16, green: 0.50, blue: 0.73)
        ),
    ]

    var body: some View {
        ZStack {
            pages[currentPage].background
                .ignoresSafeArea()
                .animation(.easeInOut, value: currentPage)

            VStack(spacing: 0) {
                Spacer()

                // Page content
                VStack(spacing: 24) {
                    Text(pages[currentPage].emoji)
                        .font(.system(size: 80))

                    Text(pages[currentPage].title)
                        .font(.title.bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(pages[currentPage].body)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.horizontal, 24)
                .animation(.easeInOut, value: currentPage)

                Spacer()

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.4))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // Navigation
                VStack(spacing: 12) {
                    Button(action: nextPage) {
                        Text(currentPage < pages.count - 1 ? "Next" : "Get Started — It's Free")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white)
                            .foregroundStyle(pages[currentPage].background)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 24)

                    if currentPage < pages.count - 1 {
                        Button("Skip") { onComplete() }
                            .foregroundStyle(.white.opacity(0.7))
                            .font(.subheadline)
                    }
                }
                .padding(.bottom, 48)
            }
        }
    }

    private func nextPage() {
        if currentPage < pages.count - 1 {
            withAnimation { currentPage += 1 }
        } else {
            onComplete()
        }
    }
}

private struct OnboardingPage {
    let emoji: String
    let title: String
    let body: String
    let background: Color
}

#Preview {
    OnboardingView(onComplete: {})
}

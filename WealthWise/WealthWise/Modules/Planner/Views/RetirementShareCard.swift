import SwiftUI

/// A share card for the Retirement Calculator — the viral growth feature.
/// Generates a visual card that users can share to social media.
struct RetirementShareCard: View {
    let userName: String
    let retirementAge: Int
    let portfolioGoal: Double
    let monthlyIncome: Double
    let monthlyContribution: Double

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 6) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)

                Text("\(userName)'s Retirement Outlook")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.08, green: 0.15, blue: 0.30), Color(red: 0.12, green: 0.44, blue: 0.35)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Stats
            VStack(spacing: 20) {
                HStack(spacing: 24) {
                    statBlock(label: "Retirement Age", value: "\(retirementAge)")
                    Divider().frame(height: 40)
                    statBlock(label: "Portfolio Goal", value: CurrencyFormatter.formatLarge(portfolioGoal))
                }

                Divider()

                HStack(spacing: 24) {
                    statBlock(label: "Monthly Income", value: CurrencyFormatter.format(monthlyIncome, compact: true))
                    Divider().frame(height: 40)
                    statBlock(label: "Investing", value: "\(CurrencyFormatter.format(monthlyContribution, compact: true))/mo")
                }

                Text("Calculate yours at WealthWise")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .background(.white)
        }
        .frame(width: 340)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
    }

    private func statBlock(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Color(red: 0.08, green: 0.15, blue: 0.30))
        }
        .frame(maxWidth: .infinity)
    }
}

/// Renders the share card as a UIImage for sharing
@MainActor
struct ShareCardRenderer {
    @MainActor
    static func render(card: RetirementShareCard) -> UIImage {
        let renderer = ImageRenderer(content: card.padding(24).background(Color(uiColor: .systemBackground)))
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage ?? UIImage()
    }
}

/// Share sheet wrapper
struct RetirementShareSheet: View {
    let result: CompoundInterestCalculator.RetirementResult
    let age: Int
    let retirementAge: Int
    let monthlyContribution: Double
    let userName: String

    @State private var showShareSheet = false

    var body: some View {
        let card = RetirementShareCard(
            userName: userName.isEmpty ? "My" : userName,
            retirementAge: retirementAge,
            portfolioGoal: result.finalBalance,
            monthlyIncome: result.monthlyIncomeAt4Percent,
            monthlyContribution: monthlyContribution
        )

        VStack(spacing: 16) {
            card

            Button {
                showShareSheet = true
            } label: {
                Label("Share My Outlook", systemImage: "square.and.arrow.up")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $showShareSheet) {
            let image = ShareCardRenderer.render(card: card)
            let text = "\(userName.isEmpty ? "My" : userName + "'s") retirement outlook: \(CurrencyFormatter.formatLarge(result.finalBalance)) by age \(retirementAge). Calculate yours with WealthWise!"

            ActivityViewController(activityItems: [text, image])
        }
    }
}

/// UIKit Activity View Controller wrapper for SwiftUI
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

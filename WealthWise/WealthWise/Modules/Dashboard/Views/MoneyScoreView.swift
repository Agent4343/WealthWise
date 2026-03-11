import SwiftUI
import Charts

struct MoneyScoreView: View {
    let scoreResult: MoneyScoreCalculator.ScoreResult

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Score Ring
                scoreRing

                // Grade
                HStack(spacing: 8) {
                    Image(systemName: scoreResult.grade.emoji)
                        .foregroundStyle(gradeColor)
                    Text(scoreResult.grade.rawValue)
                        .font(.title3.bold())
                        .foregroundStyle(gradeColor)
                }

                // Breakdown Chart
                breakdownChart

                // Component Cards
                VStack(spacing: 12) {
                    Text("Score Breakdown")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(scoreResult.breakdown) { component in
                        componentCard(component)
                    }
                }

                // Recommendations
                if !scoreResult.recommendations.isEmpty {
                    recommendationsCard
                }

                disclaimer
            }
            .padding()
        }
        .navigationTitle("Money Score")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var scoreRing: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 16)

            Circle()
                .trim(from: 0, to: Double(scoreResult.totalScore) / 100.0)
                .stroke(
                    gradeColor,
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: scoreResult.totalScore)

            VStack(spacing: 4) {
                Text("\(scoreResult.totalScore)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(gradeColor)
                Text("out of 100")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 180, height: 180)
        .padding(.top)
    }

    private var gradeColor: Color {
        switch scoreResult.grade {
        case .excellent: return .green
        case .great: return .blue
        case .good: return .teal
        case .fair: return .orange
        case .needsWork: return .red
        }
    }

    private var breakdownChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Component Scores")
                .font(.headline)

            Chart(scoreResult.breakdown) { component in
                BarMark(
                    x: .value("Score", component.score),
                    y: .value("Category", component.name)
                )
                .foregroundStyle(barColor(for: component.score))
                .annotation(position: .trailing) {
                    Text("\(component.score)")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: CGFloat(scoreResult.breakdown.count) * 36)
            .chartXScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(values: [0, 25, 50, 75, 100])
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func componentCard(_ component: MoneyScoreCalculator.ScoreComponent) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(component.name)
                    .font(.subheadline.bold())
                Spacer()
                Text("\(component.score)/100")
                    .font(.subheadline.bold())
                    .foregroundStyle(barColor(for: component.score))
                Text("(\(Int(component.weight * 100))% weight)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: Double(component.score), total: 100)
                .tint(barColor(for: component.score))

            Text(component.description)
                .font(.caption)
                .foregroundStyle(.secondary)

            if component.score < 70 {
                Text(component.suggestion)
                    .font(.caption)
                    .foregroundStyle(.accent)
                    .padding(8)
                    .background(Color.accentColor.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var recommendationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Top Recommendations")
                    .font(.headline)
            }

            ForEach(Array(scoreResult.recommendations.enumerated()), id: \.offset) { index, recommendation in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1).")
                        .font(.subheadline.bold())
                        .foregroundStyle(.accent)
                    Text(recommendation)
                        .font(.subheadline)
                        .lineSpacing(4)
                }
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var disclaimer: some View {
        Text("Money Score is an educational estimate based on general financial principles. It does not constitute financial advice. Consult a Certified Financial Planner for personalized guidance.")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }

    private func barColor(for score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }
}

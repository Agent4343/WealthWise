import SwiftUI

struct BriefDetailView: View {
    let brief: WeeklyBrief

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(brief.formattedWeekOf)
                        .font(.title2.bold())

                    if let delivered = brief.deliveredAt {
                        Text("Delivered \(delivered, format: .dateTime.month().day().year())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Section 1: Week at a Glance
                briefSection(
                    number: 1,
                    title: "Your Week at a Glance",
                    icon: "eye",
                    color: .blue,
                    content: brief.sectionOneSnapshot
                )

                // Section 2: Canadian Economic Pulse
                briefSection(
                    number: 2,
                    title: "The Canadian Economic Pulse",
                    icon: "chart.bar.fill",
                    color: .green,
                    content: brief.sectionTwoMarket
                )

                // Section 3: Your Accounts
                briefSection(
                    number: 3,
                    title: "Your Accounts This Week",
                    icon: "building.columns.fill",
                    color: .purple,
                    content: brief.sectionThreeAccounts
                )

                // Section 4: What to Think About
                briefSection(
                    number: 4,
                    title: "What to Think About",
                    icon: "lightbulb.fill",
                    color: .orange,
                    content: brief.sectionFourLearn
                )

                // Section 5: Monday Action Item
                briefSection(
                    number: 5,
                    title: "Your Monday Action Item",
                    icon: "checkmark.circle.fill",
                    color: .teal,
                    content: brief.sectionFiveAction
                )

                // Disclaimer
                Text(WeeklyBrief.disclaimer)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding()
        }
        .navigationTitle("Weekly Brief")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func briefSection(number: Int, title: String, icon: String, color: Color, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)

                VStack(alignment: .leading) {
                    Text("Section \(number)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(title)
                        .font(.headline)
                }
            }

            Text(content)
                .font(.body)
                .lineSpacing(6)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

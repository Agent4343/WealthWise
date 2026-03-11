import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct RetirementProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> RetirementProgressEntry {
        RetirementProgressEntry(
            date: Date(),
            projectedBalance: 520_000,
            monthlyContribution: 500,
            yearsToRetirement: 30,
            progressPercent: 0.15,
            currentSavings: 80_000,
            targetBalance: 520_000
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (RetirementProgressEntry) -> Void) {
        let entry = loadFromUserDefaults() ?? placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RetirementProgressEntry>) -> Void) {
        let entry = loadFromUserDefaults() ?? placeholder(in: Context())
        // Refresh every 6 hours
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 6, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadFromUserDefaults() -> RetirementProgressEntry? {
        guard let defaults = UserDefaults(suiteName: "group.com.themileschool.wealthwise") else {
            return nil
        }

        let projected = defaults.double(forKey: "widget_projected_balance")
        guard projected > 0 else { return nil }

        return RetirementProgressEntry(
            date: Date(),
            projectedBalance: projected,
            monthlyContribution: defaults.double(forKey: "widget_monthly_contribution"),
            yearsToRetirement: defaults.integer(forKey: "widget_years_to_retirement"),
            progressPercent: defaults.double(forKey: "widget_progress_percent"),
            currentSavings: defaults.double(forKey: "widget_current_savings"),
            targetBalance: projected
        )
    }
}

// MARK: - Timeline Entry

struct RetirementProgressEntry: TimelineEntry {
    let date: Date
    let projectedBalance: Double
    let monthlyContribution: Double
    let yearsToRetirement: Int
    let progressPercent: Double
    let currentSavings: Double
    let targetBalance: Double
}

// MARK: - Widget Views

struct WealthWiseWidgetEntryView: View {
    var entry: RetirementProgressProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(.green)
                Text("WealthWise")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(formatLarge(entry.projectedBalance))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.green)
                .minimumScaleFactor(0.6)

            Text("Projected at 65")
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.green.opacity(0.15))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.green)
                        .frame(width: geo.size.width * min(entry.progressPercent, 1), height: 6)
                }
            }
            .frame(height: 6)

            Text("\(formatLarge(entry.currentSavings)) saved")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var mediumWidget: some View {
        HStack(spacing: 16) {
            // Left side — progress ring
            VStack {
                ZStack {
                    Circle()
                        .stroke(Color.green.opacity(0.15), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: min(entry.progressPercent, 1))
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(Int(entry.progressPercent * 100))%")
                            .font(.title3.bold())
                        Text("saved")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 80, height: 80)
            }

            // Right side — details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundStyle(.green)
                    Text("WealthWise")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }

                Text(formatLarge(entry.projectedBalance))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)

                Text("Projected retirement portfolio")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Divider()

                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Monthly")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(formatCompact(entry.monthlyContribution))
                            .font(.caption.bold())
                    }

                    VStack(alignment: .leading) {
                        Text("Years Left")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(entry.yearsToRetirement)")
                            .font(.caption.bold())
                    }

                    VStack(alignment: .leading) {
                        Text("Current")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(formatLarge(entry.currentSavings))
                            .font(.caption.bold())
                    }
                }
            }

            Spacer()
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func formatLarge(_ amount: Double) -> String {
        if amount >= 1_000_000 {
            return String(format: "$%.1fM", amount / 1_000_000)
        } else if amount >= 1_000 {
            return String(format: "$%.0fK", amount / 1_000)
        }
        return String(format: "$%.0f", amount)
    }

    private func formatCompact(_ amount: Double) -> String {
        String(format: "$%.0f", amount)
    }
}

// MARK: - Widget Definition

struct WealthWiseWidget: Widget {
    let kind: String = "WealthWiseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RetirementProgressProvider()) { entry in
            WealthWiseWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Retirement Progress")
        .description("Track your projected retirement portfolio at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Bundle

@main
struct WealthWiseWidgetBundle: WidgetBundle {
    var body: some Widget {
        WealthWiseWidget()
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    WealthWiseWidget()
} timeline: {
    RetirementProgressEntry(
        date: Date(),
        projectedBalance: 520_000,
        monthlyContribution: 500,
        yearsToRetirement: 30,
        progressPercent: 0.15,
        currentSavings: 80_000,
        targetBalance: 520_000
    )
}

#Preview(as: .systemMedium) {
    WealthWiseWidget()
} timeline: {
    RetirementProgressEntry(
        date: Date(),
        projectedBalance: 520_000,
        monthlyContribution: 500,
        yearsToRetirement: 30,
        progressPercent: 0.15,
        currentSavings: 80_000,
        targetBalance: 520_000
    )
}

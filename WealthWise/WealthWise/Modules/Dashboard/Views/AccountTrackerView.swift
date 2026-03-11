import SwiftUI
import Charts

struct AccountTrackerView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // TFSA Tracker
                accountDetailCard(
                    title: "TFSA Contribution Room",
                    icon: "leaf.fill",
                    color: .green,
                    used: viewModel.profile?.tfsaRoomUsed ?? 0,
                    total: viewModel.tfsaMaxRoom,
                    explanation: "Your TFSA room accumulates each year ($7,000 for 2025/2026). Cumulative room since 2009 is $102,000. Withdrawals restore room on January 1st of the following year."
                )

                // RRSP Tracker
                accountDetailCard(
                    title: "RRSP Contribution Room",
                    icon: "building.columns.fill",
                    color: .blue,
                    used: viewModel.profile?.rrspRoomUsed ?? 0,
                    total: viewModel.estimatedRrspRoom,
                    explanation: "RRSP room is 18% of your previous year's earned income, up to $33,810 (2026). Unused room carries forward. Check your CRA My Account for exact figures."
                )

                // Room comparison chart
                if let profile = viewModel.profile {
                    roomComparisonChart(profile: profile)
                }

                // 1-2 Punch Strategy Card
                oneTwoPunchCard

                // Tax refund estimator
                if let profile = viewModel.profile {
                    taxRefundCard(profile: profile)
                }
            }
            .padding()
        }
        .navigationTitle("Account Tracker")
    }

    private func accountDetailCard(
        title: String,
        icon: String,
        color: Color,
        used: Double,
        total: Double,
        explanation: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
            }

            // Progress ring
            HStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(color.opacity(0.15), lineWidth: 12)

                    Circle()
                        .trim(from: 0, to: min(used / max(total, 1), 1))
                        .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(Int(min(used / max(total, 1), 1) * 100))%")
                            .font(.title3.bold())
                        Text("used")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 100, height: 100)

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Room Used")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(CurrencyFormatter.format(used, compact: true))
                            .font(.title3.bold())
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Room Remaining")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(CurrencyFormatter.format(max(0, total - used), compact: true))
                            .font(.title3.bold())
                            .foregroundStyle(color)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total Room")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(CurrencyFormatter.format(total, compact: true))
                            .font(.subheadline)
                    }
                }
            }

            Text(explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func roomComparisonChart(profile: FinancialProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Room Utilization")
                .font(.headline)

            Chart {
                BarMark(
                    x: .value("Amount", profile.tfsaRoomUsed),
                    y: .value("Account", "TFSA Used")
                )
                .foregroundStyle(.green)

                BarMark(
                    x: .value("Amount", max(0, viewModel.tfsaMaxRoom - profile.tfsaRoomUsed)),
                    y: .value("Account", "TFSA Remaining")
                )
                .foregroundStyle(.green.opacity(0.3))

                BarMark(
                    x: .value("Amount", profile.rrspRoomUsed),
                    y: .value("Account", "RRSP Used")
                )
                .foregroundStyle(.blue)

                BarMark(
                    x: .value("Amount", max(0, viewModel.estimatedRrspRoom - profile.rrspRoomUsed)),
                    y: .value("Account", "RRSP Remaining")
                )
                .foregroundStyle(.blue.opacity(0.3))
            }
            .frame(height: 120)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(CurrencyFormatter.formatLarge(amount))
                                .font(.caption2)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var oneTwoPunchCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "hands.clap.fill")
                    .foregroundStyle(.purple)
                Text("The 1-2 Punch Strategy")
                    .font(.headline)
            }

            Text("Contribute to your RRSP first to get the tax deduction. Then take your refund and invest it into your TFSA. Two tax-sheltered accounts working together.")
                .font(.subheadline)
                .lineSpacing(4)

            if let profile = viewModel.profile {
                let income = IncomeBracket(rawValue: profile.incomeBracket)?.midpoint ?? 75_000
                let province = "ON" // Default to Ontario for display
                let rrspContribution = min(5000, max(0, viewModel.estimatedRrspRoom - profile.rrspRoomUsed))
                let refund = TaxCalculator.rrspTaxRefund(
                    contribution: rrspContribution,
                    income: income,
                    province: province
                )

                if rrspContribution > 0 {
                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Step 1: RRSP")
                            Spacer()
                            Text("Contribute \(CurrencyFormatter.format(rrspContribution, compact: true))")
                                .foregroundStyle(.blue)
                        }
                        .font(.subheadline)

                        HStack {
                            Text("Tax Refund")
                            Spacer()
                            Text("~\(CurrencyFormatter.format(refund, compact: true))")
                                .foregroundStyle(.green)
                        }
                        .font(.subheadline)

                        HStack {
                            Text("Step 2: TFSA")
                            Spacer()
                            Text("Invest \(CurrencyFormatter.format(refund, compact: true)) refund")
                                .foregroundStyle(.green)
                        }
                        .font(.subheadline)

                        HStack {
                            Text("Total Tax-Sheltered")
                            Spacer()
                            Text(CurrencyFormatter.format(rrspContribution + refund, compact: true))
                                .fontWeight(.bold)
                                .foregroundStyle(.purple)
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func taxRefundCard(profile: FinancialProfile) -> some View {
        let income = IncomeBracket(rawValue: profile.incomeBracket)?.midpoint ?? 75_000
        let province = "ON"
        let marginalRate = TaxCalculator.marginalRate(income: income, province: province)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "percent")
                    .foregroundStyle(.orange)
                Text("Your Estimated Tax Rate")
                    .font(.headline)
            }

            HStack {
                VStack(alignment: .leading) {
                    Text("Marginal Rate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.formatPercent(marginalRate))
                        .font(.title2.bold())
                        .foregroundStyle(.orange)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("RRSP Deduction Value")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(CurrencyFormatter.format(marginalRate * 100, compact: true)) per $100")
                        .font(.subheadline.bold())
                }
            }

            Text("Every dollar you contribute to your RRSP reduces your taxable income by that dollar, saving you \(CurrencyFormatter.formatPercent(marginalRate)) in taxes at your current bracket.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

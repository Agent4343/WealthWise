import SwiftUI

// MARK: - Planner Tab View

struct PlannerView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Canadian Tax-Sheltered Accounts") {
                    NavigationLink(destination: RetirementBuilderView()) {
                        CalculatorRow(icon: "chart.line.uptrend.xyaxis", title: "Retirement Builder",
                                      description: "How much will your savings be worth at retirement?")
                    }
                    NavigationLink(destination: TFSAOptimizerView()) {
                        CalculatorRow(icon: "sparkles", title: "TFSA Optimizer",
                                      description: "How much is tax-free growth worth over time?")
                    }
                    NavigationLink(destination: RRSPTaxSaverView()) {
                        CalculatorRow(icon: "building.columns.fill", title: "RRSP Tax Saver",
                                      description: "What refund will your RRSP contribution generate?")
                    }
                }

                Section("Investment Fundamentals") {
                    NavigationLink(destination: FeeDragCalculatorView()) {
                        CalculatorRow(icon: "percent", title: "Fee Drag Calculator",
                                      description: "How much does a 1% MER difference cost over 25 years?")
                    }
                    NavigationLink(destination: FIRECalculatorView()) {
                        CalculatorRow(icon: "flame.fill", title: "FIRE Number",
                                      description: "How much do you need to retire on investment income?")
                    }
                }
            }
            .navigationTitle("The Planner")
        }
    }
}

struct CalculatorRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(description).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Retirement Builder

struct RetirementBuilderView: View {
    @StateObject private var vm = PlannerViewModel()

    var body: some View {
        Form {
            Section("Your Situation") {
                SliderField(label: "Current Age", value: $vm.retirementAge, range: 18...65, format: "%.0f years")
                SliderField(label: "Retirement Age", value: $vm.retirementTargetAge, range: 45...80, format: "%.0f years")
                CurrencySliderField(label: "Monthly Contribution", value: $vm.retirementMonthlyContribution, range: 0...5000, step: 50)
                CurrencySliderField(label: "Existing Savings", value: $vm.retirementExistingSavings, range: 0...500_000, step: 1000)
                SliderField(label: "Expected Annual Return", value: $vm.retirementAnnualRate, range: 3...12, format: "%.1f%%")
            }

            Section("Projection") {
                ResultRow(label: "Portfolio at Retirement",
                          value: CurrencyFormatter.formatCompact(vm.retirementProjectedValue),
                          isHighlight: true)
                ResultRow(label: "Monthly Retirement Income",
                          value: CurrencyFormatter.format(vm.retirementMonthlyIncome))
                ResultRow(label: "Cost of Waiting 5 Years",
                          value: "−\(CurrencyFormatter.formatCompact(vm.costOfWaiting5Years))",
                          isWarning: true)
            }

            Section {
                Text("Assuming \(CurrencyFormatter.formatPercent(vm.retirementAnnualRate)) annual return and 4% safe withdrawal rate. This is educational projection, not financial advice.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Retirement Builder")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - TFSA Optimizer

struct TFSAOptimizerView: View {
    @StateObject private var vm = PlannerViewModel()

    var body: some View {
        Form {
            Section("Your TFSA") {
                SliderField(label: "Your Age", value: $vm.tfsaCurrentAge, range: 18...64, format: "%.0f years")
                CurrencySliderField(label: "Annual Contribution", value: $vm.tfsaAnnualContribution, range: 500...95_000, step: 500)
                SliderField(label: "Expected Annual Return", value: $vm.tfsaRate, range: 3...12, format: "%.1f%%")
            }

            Section("Tax-Free Projection to Age 65") {
                ResultRow(label: "TFSA Value at 65",
                          value: CurrencyFormatter.formatCompact(vm.tfsaValueAt65),
                          isHighlight: true)
                ResultRow(label: "Tax Saved vs Taxable Account",
                          value: CurrencyFormatter.formatCompact(vm.tfsaTaxSaved))
            }

            Section {
                Text("Tax savings compared to equivalent taxable account at 43% average marginal rate. TFSA withdrawals are completely tax-free and restore contribution room.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("TFSA Optimizer")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - RRSP Tax Saver

struct RRSPTaxSaverView: View {
    @StateObject private var vm = PlannerViewModel()

    var body: some View {
        Form {
            Section("Your RRSP Contribution") {
                CurrencySliderField(label: "Annual Income", value: $vm.rrspIncome, range: 30_000...500_000, step: 5000)
                Picker("Province", selection: $vm.rrspProvince) {
                    ForEach(CanadianProvince.allCases, id: \.self) { p in
                        Text(p.displayName).tag(p)
                    }
                }
                CurrencySliderField(label: "RRSP Contribution", value: $vm.rrspContribution, range: 500...30_000, step: 500)
            }

            Section("Tax Impact") {
                ResultRow(label: "Estimated Tax Refund",
                          value: CurrencyFormatter.format(vm.rrspRefundEstimate),
                          isHighlight: true)
                ResultRow(label: "Net Out-of-Pocket Cost",
                          value: CurrencyFormatter.format(vm.rrspNetCost))
                ResultRow(label: "Effective Marginal Rate",
                          value: CurrencyFormatter.formatPercent(
                            TaxCalculator.marginalRate(income: vm.rrspIncome, province: vm.rrspProvince) * 100
                          ))
            }

            Section {
                Text("Estimates based on 2025 federal + provincial marginal tax brackets. Actual refund depends on deductions, credits, and CRA assessment. Consult a CFP or tax professional.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("RRSP Tax Saver")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Fee Drag Calculator

struct FeeDragCalculatorView: View {
    @StateObject private var vm = PlannerViewModel()

    var body: some View {
        Form {
            Section("Portfolio") {
                CurrencySliderField(label: "Starting Portfolio", value: $vm.feeDragPortfolio, range: 10_000...1_000_000, step: 5000)
                SliderField(label: "High MER (Mutual Fund)", value: $vm.feeDragHighMER, range: 0.5...3.0, format: "%.2f%%")
                SliderField(label: "Low MER (Index ETF)", value: $vm.feeDragLowMER, range: 0.05...1.0, format: "%.2f%%")
                SliderField(label: "Investment Horizon", value: $vm.feeDragYears, range: 5...40, format: "%.0f years")
            }

            let result = vm.feeDragResult
            Section("Fee Impact (at 7% gross return)") {
                ResultRow(label: "With \(CurrencyFormatter.formatPercent(vm.feeDragHighMER))% MER",
                          value: CurrencyFormatter.formatCompact(result.highMERValue))
                ResultRow(label: "With \(CurrencyFormatter.formatPercent(vm.feeDragLowMER))% MER",
                          value: CurrencyFormatter.formatCompact(result.lowMERValue),
                          isHighlight: true)
                ResultRow(label: "Fee Drag Cost",
                          value: CurrencyFormatter.formatCompact(result.savings),
                          isWarning: true)
            }

            Section {
                Text("The fee drag is what you lose in compounded returns by paying a higher MER. This money goes to the fund company, not you.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Fee Drag Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - FIRE Calculator

struct FIRECalculatorView: View {
    @StateObject private var vm = PlannerViewModel()

    var body: some View {
        Form {
            Section("Your FIRE Target") {
                CurrencySliderField(label: "Monthly Expenses", value: $vm.fireMonthlyExpenses, range: 1000...20_000, step: 100)
                SliderField(label: "Safe Withdrawal Rate", value: $vm.fireWithdrawalRate, range: 2.5...6.0, format: "%.1f%%")
            }

            Section("Your Path to FIRE") {
                CurrencySliderField(label: "Current Savings", value: $vm.fireCurrentSavings, range: 0...2_000_000, step: 5000)
                CurrencySliderField(label: "Monthly Investment", value: $vm.fireMonthlyContribution, range: 100...20_000, step: 100)
                SliderField(label: "Expected Return", value: $vm.fireAnnualRate, range: 3...12, format: "%.1f%%")
            }

            Section("Results") {
                ResultRow(label: "Your FIRE Number",
                          value: CurrencyFormatter.formatCompact(vm.fireNumber),
                          isHighlight: true)
                if let years = vm.yearsToFIRE {
                    ResultRow(label: "Years to FIRE",
                              value: "\(years) years")
                } else {
                    ResultRow(label: "Years to FIRE",
                              value: "Increase contributions",
                              isWarning: true)
                }
            }

            Section {
                Text("FIRE = Financial Independence, Retire Early. The \(CurrencyFormatter.formatPercent(vm.fireWithdrawalRate))% withdrawal rate means you live on \(CurrencyFormatter.formatPercent(vm.fireWithdrawalRate))% of your portfolio per year, historically sustainable for 30+ years.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("FIRE Number")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Shared Calculator Components

struct SliderField: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format: format, value))
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
            }
            Slider(value: $value, in: range)
                .tint(.blue)
        }
    }
}

struct CurrencySliderField: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text(CurrencyFormatter.format(value))
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
            }
            Slider(value: $value, in: range, step: step)
                .tint(.blue)
        }
    }
}

struct ResultRow: View {
    let label: String
    let value: String
    var isHighlight: Bool = false
    var isWarning: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(isWarning ? .orange : .primary)
            Spacer()
            Text(value)
                .fontWeight(.bold)
                .foregroundStyle(isHighlight ? .blue : isWarning ? .orange : .primary)
        }
    }
}

#Preview {
    PlannerView()
}

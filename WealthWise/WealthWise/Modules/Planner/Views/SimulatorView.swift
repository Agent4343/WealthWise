import SwiftUI
import Charts

struct SimulatorView: View {
    @StateObject private var viewModel = SimulatorViewModel()
    @EnvironmentObject private var subscriptionVM: SubscriptionViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Scenario Controls
                VStack(spacing: 16) {
                    Text("Adjust Variables")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Stepper("Current Age: \(viewModel.age)", value: $viewModel.age, in: 18...70)

                    Stepper("Retirement Age: \(viewModel.retirementAge)", value: $viewModel.retirementAge, in: 45...80)

                    VStack(alignment: .leading) {
                        Text("Monthly Investment: \(CurrencyFormatter.format(viewModel.monthlyInvestment, compact: true))")
                            .font(.subheadline)
                        Slider(value: $viewModel.monthlyInvestment, in: 100...5000, step: 50)
                    }

                    VStack(alignment: .leading) {
                        Text("Expected Return: \(CurrencyFormatter.formatPercent(viewModel.annualReturn))")
                            .font(.subheadline)
                        Slider(value: $viewModel.annualReturn, in: 0.03...0.10, step: 0.005)
                    }

                    HStack {
                        Text("Existing Savings")
                        Spacer()
                        TextField("$0", text: $viewModel.existingSavings)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Scenario Toggles
                VStack(alignment: .leading, spacing: 12) {
                    Text("Simulate Scenarios")
                        .font(.headline)

                    Toggle("Increase monthly by $200", isOn: $viewModel.scenarioIncreaseMonthly)
                    Toggle("Retire 5 years earlier", isOn: $viewModel.scenarioRetireEarly)
                    Toggle("Reduce fees by 1.5%", isOn: $viewModel.scenarioReduceFees)
                    Toggle("Start RESP ($200/mo)", isOn: $viewModel.scenarioAddRESP)
                    Toggle("Buy a home ($100K down)", isOn: $viewModel.scenarioBuyHome)
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Results Chart
                if !viewModel.baselineData.isEmpty {
                    comparisonChart
                }

                // Results Summary
                resultsSummary

                disclaimer
            }
            .padding()
        }
        .navigationTitle("Life Simulator")
        .onChange(of: viewModel.age) { _, _ in viewModel.recalculate() }
        .onChange(of: viewModel.retirementAge) { _, _ in viewModel.recalculate() }
        .onChange(of: viewModel.monthlyInvestment) { _, _ in viewModel.recalculate() }
        .onChange(of: viewModel.annualReturn) { _, _ in viewModel.recalculate() }
        .onChange(of: viewModel.existingSavings) { _, _ in viewModel.recalculate() }
        .onChange(of: viewModel.scenarioIncreaseMonthly) { _, _ in viewModel.recalculate() }
        .onChange(of: viewModel.scenarioRetireEarly) { _, _ in viewModel.recalculate() }
        .onChange(of: viewModel.scenarioReduceFees) { _, _ in viewModel.recalculate() }
        .onChange(of: viewModel.scenarioAddRESP) { _, _ in viewModel.recalculate() }
        .onChange(of: viewModel.scenarioBuyHome) { _, _ in viewModel.recalculate() }
        .onAppear { viewModel.recalculate() }
    }

    private var comparisonChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Portfolio Growth Comparison")
                .font(.headline)

            Chart {
                ForEach(viewModel.baselineData, id: \.age) { point in
                    LineMark(
                        x: .value("Age", point.age),
                        y: .value("Balance", point.balance),
                        series: .value("Scenario", "Current Plan")
                    )
                    .foregroundStyle(.blue)
                }

                if !viewModel.scenarioData.isEmpty {
                    ForEach(viewModel.scenarioData, id: \.age) { point in
                        LineMark(
                            x: .value("Age", point.age),
                            y: .value("Balance", point.balance),
                            series: .value("Scenario", "With Changes")
                        )
                        .foregroundStyle(.green)
                    }
                }
            }
            .frame(height: 250)
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(CurrencyFormatter.formatLarge(amount))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartForegroundStyleScale([
                "Current Plan": .blue,
                "With Changes": .green
            ])

            HStack(spacing: 16) {
                Label("Current Plan", systemImage: "minus")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                Label("With Changes", systemImage: "minus")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var resultsSummary: some View {
        VStack(spacing: 16) {
            HStack {
                resultColumn(
                    label: "Current Plan",
                    value: CurrencyFormatter.formatLarge(viewModel.baselineTotal),
                    color: .blue
                )

                if viewModel.hasActiveScenario {
                    Divider().frame(height: 50)

                    resultColumn(
                        label: "With Changes",
                        value: CurrencyFormatter.formatLarge(viewModel.scenarioTotal),
                        color: .green
                    )
                }
            }

            if viewModel.hasActiveScenario {
                let diff = viewModel.scenarioTotal - viewModel.baselineTotal
                HStack {
                    Image(systemName: diff >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundStyle(diff >= 0 ? .green : .red)
                    Text(diff >= 0 ? "+\(CurrencyFormatter.formatLarge(diff))" : CurrencyFormatter.formatLarge(diff))
                        .font(.title3.bold())
                        .foregroundStyle(diff >= 0 ? .green : .red)
                    Text("difference")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func resultColumn(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }

    private var disclaimer: some View {
        Text("Simulations are for educational purposes only. They assume constant rates of return and do not account for taxes, inflation adjustments, or market volatility. This is not financial advice.")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }
}

// MARK: - Simulator ViewModel

@MainActor
final class SimulatorViewModel: ObservableObject {
    @Published var age: Int = 30
    @Published var retirementAge: Int = 65
    @Published var monthlyInvestment: Double = 500
    @Published var annualReturn: Double = 0.07
    @Published var existingSavings: String = "50000"

    @Published var scenarioIncreaseMonthly = false
    @Published var scenarioRetireEarly = false
    @Published var scenarioReduceFees = false
    @Published var scenarioAddRESP = false
    @Published var scenarioBuyHome = false

    @Published var baselineData: [DataPoint] = []
    @Published var scenarioData: [DataPoint] = []
    @Published var baselineTotal: Double = 0
    @Published var scenarioTotal: Double = 0

    struct DataPoint {
        let age: Int
        let balance: Double
    }

    var hasActiveScenario: Bool {
        scenarioIncreaseMonthly || scenarioRetireEarly || scenarioReduceFees || scenarioAddRESP || scenarioBuyHome
    }

    func recalculate() {
        let existing = Double(existingSavings) ?? 0
        let years = retirementAge - age
        guard years > 0 else {
            baselineData = []
            scenarioData = []
            return
        }

        // Baseline
        baselineData = calculateGrowth(
            years: years,
            monthly: monthlyInvestment,
            annualReturn: annualReturn,
            existing: existing
        )
        baselineTotal = baselineData.last?.balance ?? 0

        // Scenario
        if hasActiveScenario {
            var scenarioMonthly = monthlyInvestment
            var scenarioReturn = annualReturn
            var scenarioYears = years
            var scenarioExisting = existing

            if scenarioIncreaseMonthly { scenarioMonthly += 200 }
            if scenarioRetireEarly { scenarioYears = max(1, years - 5) }
            if scenarioReduceFees { scenarioReturn += 0.015 }
            if scenarioAddRESP { scenarioMonthly -= 200 } // Redirect $200 to RESP
            if scenarioBuyHome { scenarioExisting = max(0, existing - 100_000) }

            scenarioData = calculateGrowth(
                years: scenarioYears,
                monthly: scenarioMonthly,
                annualReturn: scenarioReturn,
                existing: scenarioExisting
            )
            scenarioTotal = scenarioData.last?.balance ?? 0
        } else {
            scenarioData = []
            scenarioTotal = 0
        }
    }

    private func calculateGrowth(years: Int, monthly: Double, annualReturn: Double, existing: Double) -> [DataPoint] {
        let monthlyRate = annualReturn / 12
        var balance = existing
        var points: [DataPoint] = [DataPoint(age: age, balance: balance)]

        for year in 1...years {
            for _ in 1...12 {
                balance += monthly
                balance *= (1 + monthlyRate)
            }
            points.append(DataPoint(age: age + year, balance: balance))
        }

        return points
    }
}

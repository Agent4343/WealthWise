import SwiftUI
import Charts

struct RetirementCalculatorView: View {
    @ObservedObject var viewModel: PlannerViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Inputs
                VStack(spacing: 12) {
                    Stepper("Current Age: \(viewModel.retCurrentAge)",
                            value: $viewModel.retCurrentAge, in: 18...75)

                    Stepper("Retirement Age: \(viewModel.retRetirementAge)",
                            value: $viewModel.retRetirementAge, in: 45...80)

                    HStack {
                        Text("Monthly Amount")
                        Spacer()
                        TextField("$500", text: $viewModel.retMonthlyAmount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("Existing Savings")
                        Spacer()
                        TextField("$0", text: $viewModel.retExistingSavings)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    VStack(alignment: .leading) {
                        Text("Expected Return: \(CurrencyFormatter.formatPercent(viewModel.retAnnualReturn))")
                            .font(.subheadline)
                        Slider(value: $viewModel.retAnnualReturn, in: 0.02...0.12, step: 0.005)
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    viewModel.calculateRetirement()
                } label: {
                    Text("Calculate")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)

                // Results
                if let result = viewModel.retResult {
                    resultCard(result: result)

                    // Chart
                    if !result.yearByYearBalances.isEmpty {
                        growthChart(balances: result.yearByYearBalances)
                    }

                    // Share Card (Viral Growth Feature)
                    RetirementShareSheet(
                        result: result,
                        age: viewModel.retCurrentAge,
                        retirementAge: viewModel.retRetirementAge,
                        monthlyContribution: Double(viewModel.retMonthlyAmount) ?? 0,
                        userName: AuthManager.shared.currentUser?.fullName ?? ""
                    )
                    .padding(.top, 8)

                    disclaimer
                }
            }
            .padding()
        }
        .navigationTitle("Retirement Builder")
        .onAppear { viewModel.calculateRetirement() }
    }

    private func resultCard(result: CompoundInterestCalculator.RetirementResult) -> some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Projected Portfolio")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(CurrencyFormatter.format(result.finalBalance, compact: true))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
            }

            Divider()

            HStack(spacing: 20) {
                VStack {
                    Text("Monthly Income")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.format(result.monthlyIncomeAt4Percent, compact: true))
                        .font(.headline)
                }

                VStack {
                    Text("Contributed")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.formatLarge(result.totalContributions))
                        .font(.headline)
                }

                VStack {
                    Text("Interest Earned")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.formatLarge(result.totalInterestEarned))
                        .font(.headline)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func growthChart(balances: [CompoundInterestCalculator.YearBalance]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Growth Over Time")
                .font(.headline)

            Chart(balances) { balance in
                AreaMark(
                    x: .value("Age", balance.age),
                    y: .value("Balance", balance.balance)
                )
                .foregroundStyle(.green.opacity(0.2))

                LineMark(
                    x: .value("Age", balance.age),
                    y: .value("Balance", balance.balance)
                )
                .foregroundStyle(.green)

                LineMark(
                    x: .value("Age", balance.age),
                    y: .value("Contributions", balance.contributions)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(dash: [5, 3]))
            }
            .frame(height: 250)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(CurrencyFormatter.formatLarge(amount))
                                .font(.caption2)
                        }
                    }
                }
            }

            HStack(spacing: 16) {
                Label("Portfolio", systemImage: "circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
                Label("Contributions", systemImage: "circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var disclaimer: some View {
        Text("Projections are for illustrative purposes only and assume a constant rate of return. Actual returns will vary. This is not financial advice.")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
}

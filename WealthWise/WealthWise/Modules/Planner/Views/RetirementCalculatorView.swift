import SwiftUI
import Charts

struct RetirementCalculatorView: View {
    @ObservedObject var viewModel: PlannerViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Mode Toggle
                Picker("Mode", selection: $viewModel.retMode) {
                    Text("Just Me").tag(PlannerViewModel.PlanMode.solo)
                    Text("With Partner").tag(PlannerViewModel.PlanMode.couple)
                }
                .pickerStyle(.segmented)

                // Person 1 Inputs
                VStack(spacing: 12) {
                    if viewModel.retMode == .couple {
                        Text("YOUR DETAILS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

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

                // Partner Inputs
                if viewModel.retMode == .couple {
                    VStack(spacing: 12) {
                        Text("PARTNER'S DETAILS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Stepper("Current Age: \(viewModel.retPartnerAge)",
                                value: $viewModel.retPartnerAge, in: 18...75)

                        Stepper("Retirement Age: \(viewModel.retPartnerRetirementAge)",
                                value: $viewModel.retPartnerRetirementAge, in: 45...80)

                        HStack {
                            Text("Monthly Amount")
                            Spacer()
                            TextField("$300", text: $viewModel.retPartnerMonthly)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }

                        HStack {
                            Text("Existing Savings")
                            Spacer()
                            TextField("$0", text: $viewModel.retPartnerSavings)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }

                        VStack(alignment: .leading) {
                            Text("Expected Return: \(CurrencyFormatter.formatPercent(viewModel.retPartnerReturn))")
                                .font(.subheadline)
                            Slider(value: $viewModel.retPartnerReturn, in: 0.02...0.12, step: 0.005)
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Desired Income
                VStack(spacing: 8) {
                    HStack {
                        Text("Desired Monthly Income")
                        Spacer()
                        TextField("$4,000", text: $viewModel.retDesiredIncome)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    Text("How much per month do you want in retirement?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                    if viewModel.retMode == .solo {
                        soloResultCard(result: result)
                    } else if let partnerResult = viewModel.retPartnerResult {
                        coupleResultCard(result: result, partnerResult: partnerResult)
                    }

                    // Adequacy Check
                    if let adequacy = viewModel.retAdequacy {
                        adequacyCard(adequacy: adequacy)
                    }

                    // Chart
                    if !result.yearByYearBalances.isEmpty {
                        if viewModel.retMode == .couple, let partnerResult = viewModel.retPartnerResult {
                            coupleChart(balances: result.yearByYearBalances, partnerBalances: partnerResult.yearByYearBalances)
                        } else {
                            growthChart(balances: result.yearByYearBalances)
                        }
                    }

                    // Share Card
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

    private func soloResultCard(result: CompoundInterestCalculator.RetirementResult) -> some View {
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

    private func coupleResultCard(result: CompoundInterestCalculator.RetirementResult, partnerResult: CompoundInterestCalculator.RetirementResult) -> some View {
        let combined = result.finalBalance + partnerResult.finalBalance
        let combinedIncome = (combined * 0.04) / 12

        return VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Combined Portfolio")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(CurrencyFormatter.format(combined, compact: true))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
                Text("\(CurrencyFormatter.format(combinedIncome, compact: true))/mo at 4%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            HStack(spacing: 20) {
                VStack {
                    Text("You")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.format(result.finalBalance, compact: true))
                        .font(.headline)
                        .foregroundStyle(.green)
                }

                VStack {
                    Text("Partner")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.format(partnerResult.finalBalance, compact: true))
                        .font(.headline)
                        .foregroundStyle(.purple)
                }

                VStack {
                    Text("Total Contributed")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.formatLarge(result.totalContributions + partnerResult.totalContributions))
                        .font(.headline)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func adequacyCard(adequacy: PlannerViewModel.AdequacyResult) -> some View {
        VStack(spacing: 8) {
            Text(adequacy.icon)
                .font(.system(size: 40))

            Text(adequacy.title)
                .font(.title3.bold())
                .foregroundStyle(adequacy.color)

            Text(adequacy.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
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

    private func coupleChart(balances: [CompoundInterestCalculator.YearBalance], partnerBalances: [CompoundInterestCalculator.YearBalance]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Growth Over Time")
                .font(.headline)

            Chart {
                ForEach(balances) { balance in
                    LineMark(
                        x: .value("Age", balance.age),
                        y: .value("Balance", balance.balance),
                        series: .value("Person", "You")
                    )
                    .foregroundStyle(.green)
                }

                ForEach(partnerBalances) { balance in
                    LineMark(
                        x: .value("Age", balance.age),
                        y: .value("Balance", balance.balance),
                        series: .value("Person", "Partner")
                    )
                    .foregroundStyle(.purple)
                }
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
            .chartForegroundStyleScale([
                "You": .green,
                "Partner": .purple
            ])

            HStack(spacing: 16) {
                Label("You", systemImage: "circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
                Label("Partner", systemImage: "circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.purple)
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

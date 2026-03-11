import SwiftUI

struct PlannerTabView: View {
    @StateObject private var viewModel = PlannerViewModel()
    @EnvironmentObject private var subscriptionVM: SubscriptionViewModel

    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    RetirementCalculatorView(viewModel: viewModel)
                } label: {
                    calculatorRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Retirement Builder",
                        subtitle: "See what your savings become at retirement",
                        color: .green
                    )
                }

                NavigationLink {
                    TFSACalculatorView(viewModel: viewModel)
                } label: {
                    calculatorRow(
                        icon: "leaf.fill",
                        title: "TFSA Optimizer",
                        subtitle: "Tax-free growth projections",
                        color: .teal,
                        requiresBasic: true
                    )
                }
                .disabled(subscriptionVM.currentTier < .basic)

                NavigationLink {
                    RRSPCalculatorView(viewModel: viewModel)
                } label: {
                    calculatorRow(
                        icon: "building.columns.fill",
                        title: "RRSP Tax Saver",
                        subtitle: "Calculate your tax refund",
                        color: .blue,
                        requiresBasic: true
                    )
                }
                .disabled(subscriptionVM.currentTier < .basic)

                NavigationLink {
                    FeeDragCalculatorView(viewModel: viewModel)
                } label: {
                    calculatorRow(
                        icon: "scalemass.fill",
                        title: "Fee Drag Calculator",
                        subtitle: "How much high MERs cost you",
                        color: .red,
                        requiresBasic: true
                    )
                }
                .disabled(subscriptionVM.currentTier < .basic)

                NavigationLink {
                    FIRECalculatorView(viewModel: viewModel)
                } label: {
                    calculatorRow(
                        icon: "flame.fill",
                        title: "FIRE Number",
                        subtitle: "Financial independence target",
                        color: .orange,
                        requiresBasic: true
                    )
                }
                .disabled(subscriptionVM.currentTier < .basic)

                NavigationLink {
                    SimulatorView()
                } label: {
                    calculatorRow(
                        icon: "slider.horizontal.3",
                        title: "Life Simulator",
                        subtitle: "Compare financial scenarios side by side",
                        color: .purple,
                        requiresBasic: true
                    )
                }
                .disabled(subscriptionVM.currentTier < .basic)
            }
            .navigationTitle("Planner")
        }
    }

    private func calculatorRow(icon: String, title: String, subtitle: String, color: Color, requiresBasic: Bool = false) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.body.weight(.medium))

                    if requiresBasic && subscriptionVM.currentTier < .basic {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

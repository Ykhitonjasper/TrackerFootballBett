import SwiftUI
import SwiftData

struct MyBetsScreen: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel = MyBetsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView("Loading tickets…")
                case .empty:
                    EmptyStateView(
                        title: "No bets yet",
                        systemImage: "ticket",
                        message: "Pick a match and place your first paper bet."
                    )
                case .error(let message):
                    EmptyStateView(
                        title: "Couldn't load bets",
                        systemImage: "exclamationmark.triangle",
                        message: message,
                        actionTitle: "Retry"
                    ) { viewModel.load(context: context) }
                case .loaded(let bets):
                    List {
                        Section {
                            summaryHeader
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)

                        Section {
                            Picker("Filter", selection: $viewModel.selectedFilter) {
                                ForEach(MyBetsViewModel.BetFilter.allCases) { filter in
                                    Text(filter.rawValue).tag(filter)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: viewModel.selectedFilter) { _, _ in
                                viewModel.load(context: context)
                            }
                            .listRowBackground(Color.clear)
                        }

                        Section {
                            ForEach(bets) { bet in
                                NavigationLink(value: bet) {
                                    BetCard(bet: bet)
                                }
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { viewModel.load(context: context) }
                }
            }
            .screenBackground()
            .navigationTitle("My Bets")
            .navigationDestination(for: Bet.self) { bet in
                BetDetailScreen(bet: bet)
            }
            .task { viewModel.load(context: context) }
            .onReceive(NotificationCenter.default.publisher(for: .trackerBetBetPlaced)) { _ in
                viewModel.load(context: context)
            }
            .onReceive(NotificationCenter.default.publisher(for: .trackerBetSettled)) { _ in
                viewModel.load(context: context)
            }
        }
    }

    private var summaryHeader: some View {
        HStack(spacing: 10) {
            metric("Staked", CurrencyFormatter.compact(from: viewModel.totalStake), AppTheme.info)
            metric("Open", CurrencyFormatter.compact(from: viewModel.openExposure), AppTheme.warning)
            metric("P/L", CurrencyFormatter.compact(from: viewModel.totalProfitLoss), viewModel.totalProfitLoss >= 0 ? AppTheme.accent : AppTheme.danger)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func metric(_ title: String, _ value: String, _ tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .cardStyle()
    }
}

struct BetCard: View {
    let bet: Bet

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(bet.matchTitle)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Spacer()
                OutcomeBadge(outcome: bet.outcome)
            }

            HStack {
                Label(bet.type.rawValue, systemImage: "target")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text(String(format: "@ %.2f", bet.odds))
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(AppTheme.accent)
            }

            HStack {
                Text(CurrencyFormatter.string(from: bet.amount))
                    .font(.headline.monospacedDigit())
                Spacer()
                Text(bet.outcome == .pending ? "To return \(CurrencyFormatter.string(from: bet.potentialPayout))" : plText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(plColor)
            }
        }
        .padding(14)
        .cardStyle()
    }

    private var plText: String {
        let value = bet.realizedProfit
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(CurrencyFormatter.string(from: value))"
    }

    private var plColor: Color {
        if bet.outcome == .pending { return AppTheme.textSecondary }
        return bet.realizedProfit >= 0 ? AppTheme.accent : AppTheme.danger
    }
}

struct BetDetailScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let bet: Bet
    @State private var cashOutError: String?
    @State private var isCashingOut = false

    private let betting = BettingService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                detailsCard
                if bet.outcome == .pending, let match = bet.match, match.status.isBettable {
                    cashOutCard(match: match)
                }
                if !bet.note.isEmpty {
                    noteCard
                }
            }
            .padding(16)
        }
        .screenBackground()
        .navigationTitle("Ticket")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            OutcomeBadge(outcome: bet.outcome)
            Text(bet.matchTitle)
                .font(.title2.bold())
            Text(DateFormatters.full.string(from: bet.datePlaced))
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardStyle(elevated: true)
    }

    private var detailsCard: some View {
        VStack(spacing: 12) {
            row("Selection", bet.type.rawValue)
            row("Odds", String(format: "%.2f", bet.odds))
            row("Stake", CurrencyFormatter.string(from: bet.amount))
            row("Potential return", CurrencyFormatter.string(from: bet.potentialPayout))
            if let settledAt = bet.settledAt {
                row("Settled", DateFormatters.full.string(from: settledAt))
            }
            if let cashOut = bet.cashOutValue {
                row("Cash out", CurrencyFormatter.string(from: cashOut))
            }
            row("Realized P/L", CurrencyFormatter.string(from: bet.realizedProfit))
        }
        .padding(16)
        .cardStyle()
    }

    private func cashOutCard(match: Match) -> some View {
        let offer = OddsCalculator.cashOutOffer(stake: bet.amount, odds: bet.odds, match: match)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Cash out offer")
                .font(.headline)
            Text(CurrencyFormatter.string(from: offer))
                .font(.title.bold().monospacedDigit())
                .foregroundStyle(AppTheme.accent)
            Text("Demo cash out locks the ticket at the current offer.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)

            if let cashOutError {
                Text(cashOutError)
                    .foregroundStyle(AppTheme.danger)
                    .font(.caption)
            }

            Button {
                isCashingOut = true
                do {
                    try betting.cashOut(bet: bet, context: context)
                    dismiss()
                } catch let error as BettingError {
                    cashOutError = error.message
                } catch {
                    cashOutError = error.localizedDescription
                }
                isCashingOut = false
            } label: {
                if isCashingOut {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("Cash out now")
                }
            }
            .buttonStyle(PrimaryButtonStyle(isEnabled: !isCashingOut))
            .disabled(isCashingOut)
        }
        .padding(16)
        .cardStyle(elevated: true)
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note").font(.headline)
            Text(bet.note).foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardStyle()
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
        .font(.subheadline)
    }
}

struct PlaceBetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var viewModel = PlaceBetViewModel()

    let match: Match
    let betType: BetType

    private let presets: [Double] = [10, 25, 50, 100, 250]

    private var odds: Double { match.odds(for: betType) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Selection") {
                    LabeledContent("Match", value: match.displayName)
                    LabeledContent("Market", value: betType.rawValue)
                    LabeledContent("Odds", value: String(format: "%.2f", odds))
                    LabeledContent("Balance", value: CurrencyFormatter.string(from: viewModel.balance))
                }

                Section("Stake") {
                    TextField("Amount", text: $viewModel.stakeText)
                        .keyboardType(.decimalPad)
                        .font(.title2.monospacedDigit())

                    SuggestedStakeHint(balance: viewModel.balance, odds: odds) { value in
                        viewModel.setPreset(value)
                    }

                    if let stake = viewModel.stakeValue {
                        RiskMeterBadge(stake: stake, balance: viewModel.balance, odds: odds)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(presets, id: \.self) { amount in
                                StakePresetChip(
                                    amount: amount,
                                    isSelected: viewModel.stakeText == "\(Int(amount))"
                                ) {
                                    viewModel.setPreset(amount)
                                }
                            }
                            StakePresetChip(amount: max(viewModel.balance, 0), isSelected: false) {
                                viewModel.stakeText = String(format: "%.2f", viewModel.balance)
                            }
                        }
                    }
                }

                Section("Note (optional)") {
                    TextField("Why this bet?", text: $viewModel.note, axis: .vertical)
                        .lineLimit(2...4)
                }

                if let error = viewModel.errorMessage {
                    Section { Text(error).foregroundStyle(.red) }
                }
                if let success = viewModel.successMessage {
                    Section { Text(success).foregroundStyle(AppTheme.accentBright) }
                }

                Section {
                    Button {
                        viewModel.place(match: match, type: betType, context: context)
                        if viewModel.errorMessage == nil {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isPlacing {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Text("Place Bet").bold().frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(viewModel.stakeText.isEmpty || viewModel.isPlacing)
                } footer: {
                    let stake = viewModel.stakeValue ?? 0
                    Text("Potential return: \(CurrencyFormatter.string(from: stake * odds)) · Profit \(CurrencyFormatter.string(from: OddsCalculator.profit(stake: stake, odds: odds)))")
                }
            }
            .navigationTitle("Bet Slip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { viewModel.loadBalance(context: context) }
        }
    }
}

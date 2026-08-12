import SwiftUI
import SwiftData

struct MatchDetailScreen: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel: MatchDetailViewModel
    @State private var showStats = false
    @State private var showPlaceBet = false
    @State private var isWatched = false

    init(match: Match) {
        _viewModel = State(initialValue: MatchDetailViewModel(match: match))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                scoreboard
                marketSection
                InsightsCard(match: viewModel.match)
                ImpliedProbabilityBar(cells: OddsBoardBuilder.board(for: viewModel.match))
                PriceMovementChart(ticks: PriceMovementSimulator.series(for: viewModel.match))
                timelineSection
                infoSection
            }
            .padding(16)
            .padding(.bottom, 28)
        }
        .screenBackground()
        .navigationTitle(viewModel.match.league.isEmpty ? "Match" : viewModel.match.league)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 14) {
                    Button {
                        WatchlistStore.toggle(viewModel.match.id)
                        isWatched = WatchlistStore.contains(viewModel.match.id)
                    } label: {
                        Image(systemName: isWatched ? "star.fill" : "star")
                            .foregroundStyle(isWatched ? AppTheme.warning : AppTheme.textPrimary)
                    }
                    Button {
                        showStats = true
                    } label: {
                        Image(systemName: "chart.bar.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $showStats) {
            MatchStatsSheet(match: viewModel.match, stats: viewModel.stats)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showPlaceBet) {
            if let type = viewModel.selectedBetType {
                PlaceBetSheet(match: viewModel.match, betType: type)
                    .presentationDetents([.medium, .large])
            }
        }
        .onAppear {
            viewModel.reloadDerived()
            isWatched = WatchlistStore.contains(viewModel.match.id)
        }
    }

    private var scoreboard: some View {
        VStack(spacing: 16) {
            HStack {
                StatusBadge(status: viewModel.match.status)
                Spacer()
                Label(viewModel.match.sport.rawValue, systemImage: viewModel.match.sport.iconName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(viewModel.match.sport.accentColor)
            }

            HStack(alignment: .top) {
                teamBlock(name: viewModel.match.homeTeam, tint: .blue)
                VStack(spacing: 6) {
                    Text(viewModel.match.scoreLine)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text(viewModel.match.clockLabel)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(viewModel.match.status == .live ? AppTheme.danger : AppTheme.textSecondary)
                    Text(DateFormatters.full.string(from: viewModel.match.date))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTertiary)
                }
                teamBlock(name: viewModel.match.awayTeam, tint: .red)
            }
        }
        .padding(16)
        .cardStyle(elevated: true)
    }

    private func teamBlock(name: String, tint: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "shield.fill")
                .font(.system(size: 36))
                .foregroundStyle(tint.opacity(0.85))
            Text(name)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    private var marketSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Markets", subtitle: viewModel.match.status.isBettable ? "Tap a price to open the bet slip" : "Betting closed")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(viewModel.markets) { type in
                    Button {
                        viewModel.select(type)
                        if viewModel.match.status.isBettable {
                            showPlaceBet = true
                        }
                    } label: {
                        OddsButton(
                            title: type.shortCode,
                            price: viewModel.odds(for: type),
                            isSelected: viewModel.selectedBetType == type,
                            isEnabled: viewModel.match.status.isBettable
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.match.status.isBettable)
                }
            }
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Timeline", subtitle: "Key moments")
            if viewModel.timeline.isEmpty {
                Text("No events yet")
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .cardStyle()
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.timeline) { event in
                        TimelineEventRow(event: event)
                        if event.id != viewModel.timeline.last?.id {
                            Divider().overlay(AppTheme.border)
                        }
                    }
                }
                .cardStyle()
            }
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Details")
            infoRow("Venue", viewModel.match.venue.isEmpty ? "TBD" : viewModel.match.venue)
            infoRow("Competition", viewModel.match.league.isEmpty ? viewModel.match.sport.rawValue : viewModel.match.league)
            infoRow("Popularity", "\(viewModel.match.popularity)/100")
        }
        .padding(14)
        .cardStyle()
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
        .font(.subheadline)
    }
}

struct TimelineEventRow: View {
    let event: TimelineEvent

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(event.timeLabel)
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 36, alignment: .leading)

            Image(systemName: event.type.icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(event.type == .yellowCard ? .black : .white)
                .padding(6)
                .background(event.type.tint)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(event.description)
                    .font(.subheadline)
                Text(event.isHome ? "Home" : "Away")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textTertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

struct MatchStatsSheet: View {
    let match: Match
    let stats: MatchStats
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text(match.displayName)
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    ForEach(stats.rows, id: \.title) { row in
                        VStack(spacing: 8) {
                            HStack {
                                Text(row.home).font(.subheadline.weight(.bold)).monospacedDigit()
                                Spacer()
                                Text(row.title).font(.caption).foregroundStyle(AppTheme.textSecondary)
                                Spacer()
                                Text(row.away).font(.subheadline.weight(.bold)).monospacedDigit()
                            }
                            GeometryReader { geo in
                                let total = max(row.homeValue + row.awayValue, 1)
                                HStack(spacing: 3) {
                                    Capsule()
                                        .fill(AppTheme.accent)
                                        .frame(width: geo.size.width * (row.homeValue / total))
                                    Capsule()
                                        .fill(Color.red.opacity(0.75))
                                        .frame(width: geo.size.width * (row.awayValue / total))
                                }
                            }
                            .frame(height: 6)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Match Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

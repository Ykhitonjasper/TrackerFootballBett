import SwiftUI
import SwiftData

struct MatchDetailScreen: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel: MatchDetailViewModel
    @State private var showStats = false
    @State private var isWatched = false

    init(match: Match) {
        _viewModel = State(initialValue: MatchDetailViewModel(match: match))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                scoreboard
                OneXTwoBoard(match: viewModel.match)
                ForEach(viewModel.match.picks ?? []) { pick in
                    PickCard(pick: pick)
                }
                FormPreviewCard(match: viewModel.match)
                InsightsCard(match: viewModel.match)
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

struct OneXTwoBoard: View {
    let match: Match

    var body: some View {
        let selected = match.primaryPick
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Result board", subtitle: "Highlighted forecast — for personal notes only")
            HStack(spacing: 8) {
                cell("1", match.homeTeam, on: selected?.market == .oneXTwo && selected?.lean == .home)
                if match.sport.allowsDraw {
                    cell("X", "Draw", on: selected?.market == .oneXTwo && selected?.lean == .draw)
                }
                cell("2", match.awayTeam, on: selected?.market == .oneXTwo && selected?.lean == .away)
            }
            if let pick = selected, pick.market != .oneXTwo {
                Text("Also noted: \(pick.selectionLabel)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(14)
        .cardStyle()
    }

    private func cell(_ code: String, _ caption: String, on: Bool) -> some View {
        VStack(spacing: 6) {
            Text(code)
                .font(.title2.weight(.bold).monospaced())
            Text(caption)
                .font(.caption2)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(on ? .white : AppTheme.textSecondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(on ? AppTheme.accent : AppTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct FormPreviewCard: View {
    let match: Match

    var body: some View {
        let preview = MatchPreviewFactory.preview(for: match)
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Form & H2H", subtitle: "Last five plus recent meetings")
            formRow(match.homeTeam, preview.home)
            formRow(match.awayTeam, preview.away)
            HStack {
                mini("Home H2H", "\(preview.homeWins)")
                mini("Draws", "\(preview.draws)")
                mini("Away H2H", "\(preview.awayWins)")
            }
            Text(preview.note)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(14)
        .cardStyle()
    }

    private func formRow(_ name: String, _ row: MatchPreviewFactory.FormRow) -> some View {
        HStack {
            Text(name)
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 4) {
                ForEach(Array(row.lastFive.enumerated()), id: \.offset) { _, token in
                    Text(token)
                        .font(.caption2.weight(.bold))
                        .frame(width: 18, height: 18)
                        .background(token == "W" ? AppTheme.success.opacity(0.3) : token == "L" ? AppTheme.danger.opacity(0.3) : AppTheme.surfaceElevated)
                        .clipShape(Circle())
                }
            }
            Text("\(row.scored):\(row.conceded)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppTheme.textTertiary)
        }
    }

    private func mini(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.headline.monospacedDigit())
            Text(title).font(.caption2).foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(AppTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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

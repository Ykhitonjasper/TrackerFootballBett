import SwiftUI
import SwiftData

struct CoachTipsCard: View {
    let balance: Double
    let pendingCount: Int
    let netProfit: Double

    private var tips: [DemoScenario] {
        ScenarioCoach.activeScenarios(balance: balance, pendingCount: pendingCount, netProfit: netProfit)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Coach tips", subtitle: "Session guidance for the demo bankroll")
            ForEach(tips, id: \.title) { tip in
                VStack(alignment: .leading, spacing: 4) {
                    Text(tip.title)
                        .font(.subheadline.weight(.semibold))
                    Text(tip.tip)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(14)
        .cardStyle()
    }
}

struct LeagueBadge: View {
    let leagueName: String

    var body: some View {
        if let info = LeagueCatalog.info(named: leagueName) {
            Text(info.shortCode)
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color(hex: info.accentHex)?.opacity(0.25) ?? AppTheme.surfaceElevated)
                .foregroundStyle(Color(hex: info.accentHex) ?? AppTheme.textSecondary)
                .clipShape(Capsule())
        } else if !leagueName.isEmpty {
            Text(leagueName)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}

struct ImpliedProbabilityBar: View {
    let cells: [OddsBoardBuilder.Cell]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Implied probabilities")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
            ForEach(cells.prefix(4)) { cell in
                HStack {
                    Text(cell.type.shortCode)
                        .font(.caption.weight(.bold))
                        .frame(width: 44, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(AppTheme.surfaceElevated)
                            Capsule()
                                .fill(AppTheme.accent)
                                .frame(width: max(6, geo.size.width * cell.implied))
                        }
                    }
                    .frame(height: 8)
                    Text(String(format: "%.0f%%", cell.implied * 100))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
        .padding(12)
        .cardStyle()
    }
}

struct MatchQuickActions: View {
    let match: Match
    var onBet: (BetType) -> Void
    var onStats: () -> Void
    var onToggleWatch: () -> Void
    var isWatched: Bool

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onStats) {
                Label("Stats", systemImage: "chart.bar.fill")
            }
            .buttonStyle(SecondaryButtonStyle())

            Button(action: onToggleWatch) {
                Label(isWatched ? "Watching" : "Watch", systemImage: isWatched ? "star.fill" : "star")
            }
            .buttonStyle(SecondaryButtonStyle())

            if match.status.isBettable, let type = BetType.marketTypes(for: match.sport).first {
                Button {
                    onBet(type)
                } label: {
                    Label("Bet", systemImage: "plus.circle.fill")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }
}

#Preview("Match card") {
    let match = Match(
        homeTeam: "Arsenal",
        awayTeam: "Chelsea",
        date: Date(),
        sport: .soccer,
        status: .live,
        homeOdds: 2.1,
        awayOdds: 3.4,
        drawOdds: 3.2,
        homeScore: 1,
        awayScore: 1,
        league: "Premier League",
        venue: "Emirates Stadium",
        minute: 67,
        isFeatured: true,
        popularity: 98
    )
    return MatchCard(match: match)
        .padding()
        .screenBackground()
}

#Preview("Bet card") {
    let match = Match(
        homeTeam: "Lakers",
        awayTeam: "Warriors",
        date: Date(),
        sport: .basketball,
        status: .upcoming,
        homeOdds: 1.9,
        awayOdds: 1.95,
        league: "NBA"
    )
    let bet = Bet(amount: 50, odds: 1.9, type: .homeWin, match: match)
    return BetCard(bet: bet)
        .padding()
        .screenBackground()
}

#Preview("Onboarding") {
    OnboardingScreen()
        .modelContainer(for: [UserProfile.self, Bet.self, Match.self], inMemory: true)
}

#Preview("Help") {
    NavigationStack { HelpScreen() }
}

import SwiftUI
import SwiftData

struct CoachTipsCard: View {
    let watchCount: Int
    let liveCount: Int

    private var tips: [CoachTip] {
        ScenarioCoach.activeTips(watchCount: watchCount, liveCount: liveCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Quick tips", subtitle: "Get more from Match Journal")
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

struct MatchQuickActions: View {
    let match: Match
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

#Preview("Onboarding") {
    OnboardingScreen()
        .modelContainer(for: [UserProfile.self, Match.self, MatchPick.self], inMemory: true)
}

#Preview("Help") {
    NavigationStack { HelpScreen() }
}

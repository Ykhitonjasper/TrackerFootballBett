import SwiftUI

struct HelpScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                intro
                section(
                    title: "Paper bankroll",
                    body: "TrackerFootballBett starts you with $1,000 in demo funds. Wins and losses update this balance only. There is no real-money wagering, deposits, or withdrawals."
                )
                section(
                    title: "Placing a bet",
                    body: "Open any upcoming or live match, choose a market price, enter a stake, and confirm. Your stake is reserved immediately and the potential return is stake × odds."
                )
                section(
                    title: "Settlement",
                    body: "When a simulated match reaches Full Time, open tickets on that fixture settle automatically. Winning tickets credit stake × odds back to your bankroll; losing tickets settle at zero return."
                )
                section(
                    title: "Cash out",
                    body: "Pending tickets on live or upcoming markets can be cashed out at a demo offer. Cash out locks the ticket early for the displayed amount."
                )
                section(
                    title: "Live simulation",
                    body: "Scores, minutes, and prices evolve on a timer so the feed feels alive. Featured fixtures and deeper league slates are generated from the built-in team catalog."
                )
                section(
                    title: "Leaderboard",
                    body: "Ranks are ordered by net profit. Your profile appears alongside generated rivals so you can track relative performance during a demo session."
                )
                glossary
                NavigationLink("Full market rules") {
                    MarketRulesScreen()
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
                responsible
            }
            .padding(16)
        }
        .screenBackground()
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How TrackerFootballBett works")
                .font(.title2.bold())
            Text("A compact sports tracking and paper-betting sandbox for exploring markets, tickets, and performance stats.")
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(16)
        .cardStyle(elevated: true)
    }

    private var glossary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Glossary")
                .font(.headline)
            glossaryRow("1 / X / 2", "Home win, draw, away win.")
            glossaryRow("Over / Under 2.5", "Total goals/points line for soccer-style markets.")
            glossaryRow("BTTS", "Both teams to score.")
            glossaryRow("1X / X2", "Double chance markets.")
            glossaryRow("ROI", "Net profit divided by total amount staked.")
            glossaryRow("Edge", "Estimated advantage versus implied probability.")
        }
        .padding(16)
        .cardStyle()
    }

    private var responsible: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Responsible demo use")
                .font(.headline)
            Text("This project is for UI/UX and product exploration. It intentionally avoids payments, KYC, and real operator integrations.")
                .font(.footnote)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(16)
        .cardStyle()
    }

    private func section(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardStyle()
    }

    private func glossaryRow(_ term: String, _ meaning: String) -> some View {
        HStack(alignment: .top) {
            Text(term)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 110, alignment: .leading)
            Text(meaning)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer(minLength: 0)
        }
    }
}

struct MarketRulesReference {
    struct Rule: Identifiable, Hashable {
        let id = UUID()
        let market: BetType
        let summary: String
        let settlesWhen: String
    }

    static let all: [Rule] = [
        Rule(market: .homeWin, summary: "Home team wins in regulation/result window used by the sport.", settlesWhen: "Final score home > away"),
        Rule(market: .awayWin, summary: "Away team wins the match.", settlesWhen: "Final score away > home"),
        Rule(market: .draw, summary: "Neither side wins.", settlesWhen: "Final score tied"),
        Rule(market: .over, summary: "Combined score exceeds 2.5.", settlesWhen: "home + away >= 3"),
        Rule(market: .under, summary: "Combined score stays under 2.5.", settlesWhen: "home + away <= 2"),
        Rule(market: .bothTeamsScore, summary: "Each side scores at least once.", settlesWhen: "home > 0 and away > 0"),
        Rule(market: .homeOrDraw, summary: "Home win or draw (double chance).", settlesWhen: "home >= away"),
        Rule(market: .awayOrDraw, summary: "Away win or draw (double chance).", settlesWhen: "away >= home")
    ]
}

struct MarketRulesScreen: View {
    var body: some View {
        List(MarketRulesReference.all) { rule in
            VStack(alignment: .leading, spacing: 6) {
                Text(rule.market.rawValue)
                    .font(.headline)
                Text(rule.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Settles when: \(rule.settlesWhen)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.accent)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Market rules")
    }
}

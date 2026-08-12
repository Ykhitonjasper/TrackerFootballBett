import Foundation

enum MockStatsFactory {
    static func stats(for match: Match) -> MatchStats {
        let homeBias = Double(match.homeScore + 1) / Double(match.totalGoals + 2)
        let possessionHome = Int((38 + homeBias * 24 + Double.random(in: -4...4)).rounded())
        let possession = min(68, max(32, possessionHome))

        let shotsHome = max(match.homeScore, Int.random(in: 3...16))
        let shotsAway = max(match.awayScore, Int.random(in: 3...16))

        return MatchStats(
            possessionHome: possession,
            possessionAway: 100 - possession,
            shotsHome: shotsHome,
            shotsAway: shotsAway,
            shotsOnTargetHome: min(shotsHome, match.homeScore + Int.random(in: 1...5)),
            shotsOnTargetAway: min(shotsAway, match.awayScore + Int.random(in: 1...5)),
            cornersHome: Int.random(in: 1...10),
            cornersAway: Int.random(in: 1...10),
            foulsHome: Int.random(in: 4...18),
            foulsAway: Int.random(in: 4...18),
            yellowCardsHome: Int.random(in: 0...4),
            yellowCardsAway: Int.random(in: 0...4),
            redCardsHome: Int.random(in: 0...1),
            redCardsAway: Int.random(in: 0...1),
            passesHome: Int.random(in: 220...620),
            passesAway: Int.random(in: 220...620)
        )
    }
}

import Foundation

/// Generates synthetic price ticks for match detail charts in the demo.
enum PriceMovementSimulator {
    struct Tick: Identifiable, Hashable {
        let id = UUID()
        let minute: Int
        let home: Double
        let draw: Double?
        let away: Double
    }

    static func series(for match: Match, points: Int = 12) -> [Tick] {
        var ticks: [Tick] = []
        var home = match.homeOdds
        var away = match.awayOdds
        var draw = match.drawOdds
        let upper = max(match.minute, match.status == .finished ? 90 : 60)

        for index in 0..<points {
            let minute = points == 1 ? upper : Int(Double(upper) * Double(index) / Double(points - 1))
            let shock = Double.random(in: -0.07...0.07)
            home = max(1.2, ((home + shock) * 100).rounded() / 100)
            away = max(1.2, ((away - shock * 0.8) * 100).rounded() / 100)
            if let currentDraw = draw {
                draw = max(2.3, ((currentDraw + Double.random(in: -0.04...0.04)) * 100).rounded() / 100)
            }
            ticks.append(Tick(minute: minute, home: home, draw: draw, away: away))
        }

        // Anchor final tick to current market.
        if var last = ticks.last {
            last = Tick(minute: last.minute, home: match.homeOdds, draw: match.drawOdds, away: match.awayOdds)
            ticks[ticks.count - 1] = last
        }
        return ticks
    }

    static func volatilityScore(for ticks: [Tick]) -> Double {
        guard ticks.count > 1 else { return 0 }
        var total = 0.0
        for index in 1..<ticks.count {
            total += abs(ticks[index].home - ticks[index - 1].home)
            total += abs(ticks[index].away - ticks[index - 1].away)
        }
        return (total / Double(ticks.count - 1) * 100).rounded() / 100
    }
}

enum TicketRiskMeter {
    enum Band: String {
        case conservative = "Conservative"
        case balanced = "Balanced"
        case aggressive = "Aggressive"
        case speculative = "Speculative"

        var detail: String {
            switch self {
            case .conservative: return "Short prices, smaller swings."
            case .balanced: return "Standard single-bet profile."
            case .aggressive: return "Longer odds or larger fraction of bankroll."
            case .speculative: return "High variance — size down if streaking poorly."
            }
        }
    }

    static func band(stake: Double, balance: Double, odds: Double) -> Band {
        let fraction = balance > 0 ? stake / balance : 1
        if odds >= 4.0 || fraction >= 0.2 { return .speculative }
        if odds >= 2.6 || fraction >= 0.12 { return .aggressive }
        if odds <= 1.7 && fraction <= 0.05 { return .conservative }
        return .balanced
    }

    static func color(for band: Band) -> String {
        switch band {
        case .conservative: return "#29B6F6"
        case .balanced: return "#3498DB"
        case .aggressive: return "#F39C12"
        case .speculative: return "#E74C3C"
        }
    }
}

enum SearchSuggestions {
    static func suggest(from query: String) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return ["Arsenal", "Lakers", "Djokovic", "T1", "Maple Leafs", "Yankees"]
        }
        var results = TeamCatalog.searchTeams(query: trimmed, limit: 8)
        let leagues = LeagueCatalog.all
            .map(\.name)
            .filter { $0.localizedCaseInsensitiveContains(trimmed) }
        results.append(contentsOf: leagues)
        return Array(Set(results)).sorted().prefix(10).map { $0 }
    }
}

enum AppCopy {
    static let disclaimer = "TrackerFootballBett is a paper-betting product demo. It does not offer real-money gambling."
    static let resetWarning = "Resetting clears tickets and restores the starter bankroll and fixture slate."
    static let liveHint = "Live markets update on a short timer. Settlement runs when fixtures finish."
    static let watchlistHint = "Star fixtures to revisit them quickly from Profile → Watchlist."
}

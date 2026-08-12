import Foundation

/// Builds human-readable ticket and match copy used across cards and details.
enum CopyFactory {
    static func betSummary(_ bet: Bet) -> String {
        "\(bet.type.shortCode) @ \(String(format: "%.2f", bet.odds)) · \(CurrencyFormatter.string(from: bet.amount))"
    }

    static func matchSubtitle(_ match: Match) -> String {
        let league = match.league.isEmpty ? match.sport.rawValue : match.league
        return "\(league) · \(match.clockLabel)"
    }

    static func settlementBlurb(won: Bool, payout: Double) -> String {
        if won {
            return "Ticket won · credited \(CurrencyFormatter.string(from: payout))"
        }
        return "Ticket lost · stake not returned"
    }

    static func onboardingTagline(for sport: Sport) -> String {
        switch sport {
        case .soccer: return "Track leagues and live scorelines across Europe's top clubs."
        case .basketball: return "Follow NBA and EuroLeague tips with fast-moving totals."
        case .tennis: return "Tour matchups with set-by-set momentum cues."
        case .baseball: return "MLB slates with inning-aware live states."
        case .hockey: return "NHL and KHL cards with draw-friendly markets."
        case .esports: return "CS2, LoL, and Dota maps with objective-driven timelines."
        }
    }

    static func emptyFeedMessage(sport: Sport?, status: FeedStatusFilter) -> String {
        if let sport {
            return "No \(status.rawValue.lowercased()) \(sport.rawValue.lowercased()) fixtures right now."
        }
        return "No \(status.rawValue.lowercased()) fixtures match your filters."
    }

    static func levelUpMessage(level: Int, title: String) -> String {
        "You reached level \(level) — \(title). Keep stacking disciplined tickets."
    }
}

enum OddsBoardBuilder {
    struct Cell: Identifiable, Hashable {
        let id = UUID()
        let type: BetType
        let odds: Double
        let implied: Double
    }

    static func board(for match: Match) -> [Cell] {
        BetType.marketTypes(for: match.sport).map { type in
            let odds = match.odds(for: type)
            return Cell(type: type, odds: odds, implied: OddsCalculator.impliedProbability(odds))
        }
    }

    static func bestPrice(on match: Match) -> Cell? {
        board(for: match).max(by: { $0.odds < $1.odds })
    }

    static func shortestPrice(on match: Match) -> Cell? {
        board(for: match).min(by: { $0.odds < $1.odds })
    }
}

enum FeedSectioning {
    struct Section: Identifiable, Hashable {
        let id: String
        let title: String
        let matches: [Match]
    }

    static func group(_ matches: [Match]) -> [Section] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: matches) { match -> String in
            if match.status == .live { return "Live now" }
            if calendar.isDateInToday(match.date) { return "Today" }
            if calendar.isDateInTomorrow(match.date) { return "Tomorrow" }
            return DateFormatters.shortDate.string(from: match.date)
        }

        let order = ["Live now", "Today", "Tomorrow"]
        return grouped.keys.sorted { lhs, rhs in
            let li = order.firstIndex(of: lhs) ?? 999
            let ri = order.firstIndex(of: rhs) ?? 999
            if li != ri { return li < ri }
            return lhs < rhs
        }.map { key in
            Section(id: key, title: key, matches: (grouped[key] ?? []).sorted { $0.date < $1.date })
        }
    }
}

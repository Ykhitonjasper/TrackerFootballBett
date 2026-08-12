import Foundation

/// Maps common search aliases and abbreviations to canonical entities.
enum AliasIndex {
    static let teamAliases: [String: String] = [
        "man utd": "Manchester United",
        "man united": "Manchester United",
        "man city": "Manchester City",
        "spurs": "Tottenham",
        "barca": "Barcelona",
        "inter milan": "Inter",
        "psg": "Paris",
        "bvb": "Borussia Dortmund",
        "gs": "Golden State",
        "lal": "Lakers",
        "bos": "Celtics",
        "nyi": "Rangers",
        "tor": "Maple Leafs",
        "navi": "Natus Vincere",
        "c9": "Cloud9"
    ]

    static let leagueAliases: [String: String] = [
        "epl": "Premier League",
        "pl": "Premier League",
        "ucl": "Champions League",
        "nba": "NBA",
        "mlb": "MLB",
        "nhl": "NHL",
        "cs": "CS2",
        "csgo": "CS2",
        "league of legends": "LoL"
    ]

    static func resolveTeam(_ query: String) -> String? {
        let key = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let alias = teamAliases[key] { return alias }
        return TeamCatalog.allTeamNames.first { $0.localizedCaseInsensitiveContains(query) }
    }

    static func resolveLeague(_ query: String) -> String? {
        let key = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let alias = leagueAliases[key] { return alias }
        return LeagueCatalog.all.first { $0.name.localizedCaseInsensitiveContains(query) }?.name
    }

    static func expandQuery(_ query: String) -> String {
        if let team = resolveTeam(query) { return team }
        if let league = resolveLeague(query) { return league }
        return query
    }
}

enum FixtureDensity {
    static func count(bySport matches: [Match]) -> [Sport: Int] {
        var map: [Sport: Int] = [:]
        for match in matches {
            map[match.sport, default: 0] += 1
        }
        return map
    }

    static func count(byStatus matches: [Match]) -> [MatchStatus: Int] {
        var map: [MatchStatus: Int] = [:]
        for match in matches {
            map[match.status, default: 0] += 1
        }
        return map
    }

    static func summaryLine(for matches: [Match]) -> String {
        let live = matches.filter { $0.status == .live }.count
        let upcoming = matches.filter { $0.status == .upcoming }.count
        let finished = matches.filter { $0.status == .finished }.count
        return "\(live) live · \(upcoming) upcoming · \(finished) finished"
    }
}

enum XPRules {
    static let placeBet = 5
    static let winBet = 20
    static let loseBet = 2
    static let cashOut = 3
    static let dailyOpen = 1

    static func title(for level: Int) -> String {
        switch level {
        case ...2: return "Rookie"
        case 3...5: return "Regular"
        case 6...9: return "Sharp"
        case 10...14: return "Pro"
        default: return "Legend"
        }
    }

    static func xpNeeded(for level: Int) -> Int {
        max(100, level * 100)
    }
}

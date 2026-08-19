import Foundation

/// Additional league metadata used by filters, badges, and insights.
enum LeagueCatalog {
    struct LeagueInfo: Identifiable, Hashable {
        let id: String
        let name: String
        let sport: Sport
        let country: String
        let tier: Int
        let accentHex: String

        var shortCode: String {
            name.split(separator: " ").prefix(2).map { String($0.prefix(1)).uppercased() }.joined()
        }
    }

    static let all: [LeagueInfo] = [
        LeagueInfo(id: "epl", name: "Premier League", sport: .soccer, country: "England", tier: 1, accentHex: "#3D195B"),
        LeagueInfo(id: "laliga", name: "La Liga", sport: .soccer, country: "Spain", tier: 1, accentHex: "#EE8700"),
        LeagueInfo(id: "seriea", name: "Serie A", sport: .soccer, country: "Italy", tier: 1, accentHex: "#024494"),
        LeagueInfo(id: "bundesliga", name: "Bundesliga", sport: .soccer, country: "Germany", tier: 1, accentHex: "#D20515"),
        LeagueInfo(id: "nba", name: "NBA", sport: .basketball, country: "USA", tier: 1, accentHex: "#1D428A"),
        LeagueInfo(id: "euroleague", name: "EuroLeague", sport: .basketball, country: "Europe", tier: 1, accentHex: "#F6851F"),
        LeagueInfo(id: "atp", name: "ATP", sport: .tennis, country: "World", tier: 1, accentHex: "#00A3E0"),
        LeagueInfo(id: "wta", name: "WTA", sport: .tennis, country: "World", tier: 1, accentHex: "#6B2D7B"),
        LeagueInfo(id: "mlb", name: "MLB", sport: .baseball, country: "USA", tier: 1, accentHex: "#002878"),
        LeagueInfo(id: "nhl", name: "NHL", sport: .hockey, country: "North America", tier: 1, accentHex: "#111111"),
        LeagueInfo(id: "khl", name: "KHL", sport: .hockey, country: "Eurasia", tier: 1, accentHex: "#E30613"),
        LeagueInfo(id: "cs2", name: "CS2", sport: .esports, country: "Global", tier: 1, accentHex: "#DE9B35"),
        LeagueInfo(id: "lol", name: "LoL", sport: .esports, country: "Global", tier: 1, accentHex: "#0BC4E2"),
        LeagueInfo(id: "dota", name: "Dota 2", sport: .esports, country: "Global", tier: 1, accentHex: "#A80707")
    ]

    static func info(named name: String) -> LeagueInfo? {
        all.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    static func leagues(for sport: Sport) -> [LeagueInfo] {
        all.filter { $0.sport == sport }.sorted { $0.tier < $1.tier }
    }
}

enum CoachTip {
    case openDesk
    case firstStar
    case liveNow
    case mixSports

    var title: String {
        switch self {
        case .openDesk: return "Read predictions"
        case .firstStar: return "Build a watchlist"
        case .liveNow: return "Live scores"
        case .mixSports: return "Switch sports"
        }
    }

    var tip: String {
        switch self {
        case .openDesk:
            return "Start on the Predictions tab. Each card is a written forecast with a confidence pip."
        case .firstStar:
            return "Open a featured soccer fixture and tap the star to pin it under Profile."
        case .liveNow:
            return "Live games refresh the clock and score — start from the Live filter."
        case .mixSports:
            return "Use the sport chips to jump from soccer into NBA, tennis, or esports."
        }
    }
}

enum ScenarioCoach {
    static func activeTips(watchCount: Int, liveCount: Int) -> [CoachTip] {
        var tips: [CoachTip] = [.openDesk]
        if watchCount == 0 { tips.append(.firstStar) }
        if liveCount > 0 { tips.append(.liveNow) }
        tips.append(.mixSports)
        return tips
    }
}

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

enum DemoScenario {
    case firstBet
    case liveComeback
    case bankrollRebuild
    case rebuildDiscipline

    var title: String {
        switch self {
        case .firstBet: return "First ticket"
        case .liveComeback: return "Live comeback"
        case .bankrollRebuild: return "Bankroll rebuild"
        case .rebuildDiscipline: return "Steady recovery"
        }
    }

    var tip: String {
        switch self {
        case .firstBet:
            return "Start with a featured soccer moneyline under 5% of bankroll."
        case .liveComeback:
            return "When a favorite trails live, look at double chance instead of chasing long moneylines."
        case .bankrollRebuild:
            return "After a losing streak, cut stake size and favor shorter prices."
        case .rebuildDiscipline:
            return "Consistency beats parlays when rebuilding after a downswing."
        }
    }
}

enum ScenarioCoach {
    static func activeScenarios(balance: Double, pendingCount: Int, netProfit: Double) -> [DemoScenario] {
        var scenarios: [DemoScenario] = []
        if pendingCount == 0 { scenarios.append(.firstBet) }
        if balance < 700 { scenarios.append(.bankrollRebuild) }
        if netProfit < 0 { scenarios.append(.rebuildDiscipline) }
        scenarios.append(.liveComeback)
        return scenarios
    }
}

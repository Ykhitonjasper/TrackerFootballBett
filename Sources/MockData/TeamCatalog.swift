import Foundation

enum TeamCatalog {
    struct LeagueRoster {
        let league: String
        let teams: [String]
    }

    static let soccerLeagues: [LeagueRoster] = [
        LeagueRoster(league: "Premier League", teams: ["Arsenal", "Chelsea", "Liverpool", "Manchester City", "Manchester United", "Tottenham", "Newcastle", "Aston Villa", "Brighton", "West Ham", "Fulham", "Brentford", "Crystal Palace", "Wolves", "Everton", "Nottingham Forest", "Bournemouth", "Leicester", "Ipswich", "Southampton"]),
        LeagueRoster(league: "La Liga", teams: ["Real Madrid", "Barcelona", "Atletico Madrid", "Sevilla", "Real Sociedad", "Villarreal", "Athletic Bilbao", "Betis", "Osasuna", "Girona", "Mallorca", "Valencia", "Getafe", "Celta Vigo", "Las Palmas", "Alaves", "Rayo Vallecano", "Espanyol", "Leganes", "Valladolid"]),
        LeagueRoster(league: "Serie A", teams: ["Inter", "AC Milan", "Juventus", "Napoli", "Roma", "Lazio", "Atalanta", "Fiorentina", "Bologna", "Torino", "Udinese", "Monza", "Genoa", "Cagliari", "Lecce", "Empoli", "Hellas Verona", "Frosinone", "Sassuolo", "Salernitana"]),
        LeagueRoster(league: "Bundesliga", teams: ["Bayern Munich", "Borussia Dortmund", "RB Leipzig", "Bayer Leverkusen", "Eintracht Frankfurt", "Wolfsburg", "Freiburg", "Hoffenheim", "Stuttgart", "Gladbach", "Werder Bremen", "Augsburg", "Union Berlin", "Mainz", "Heidenheim", "Bochum", "Koln", "Darmstadt"]),
    ]

    static let basketballLeagues: [LeagueRoster] = [
        LeagueRoster(league: "NBA", teams: ["Lakers", "Warriors", "Celtics", "Nets", "Bucks", "Heat", "Suns", "Nuggets", "Mavericks", "Clippers", "76ers", "Knicks", "Bulls", "Cavaliers", "Kings", "Grizzlies", "Timberwolves", "Thunder", "Pacers", "Pelicans"]),
        LeagueRoster(league: "EuroLeague", teams: ["Real Madrid BB", "Barcelona BB", "Olympiacos", "Panathinaikos", "Fenerbahce", "CSKA", "Efes", "Maccabi Tel Aviv", "Zalgiris", "Bayern Munich BB"]),
    ]

    static let tennisLeagues: [LeagueRoster] = [
        LeagueRoster(league: "ATP", teams: ["Djokovic", "Alcaraz", "Sinner", "Medvedev", "Zverev", "Tsitsipas", "Ruud", "Rublev", "Rune", "Hurkacz", "Fritz", "Tiafoe", "De Minaur", "Paul", "Dimitrov"]),
        LeagueRoster(league: "WTA", teams: ["Swiatek", "Sabalenka", "Gauff", "Rybakina", "Pegula", "Jabeur", "Ons", "Keys", "Bencic", "Ostapenko"]),
    ]

    static let baseballLeagues: [LeagueRoster] = [
        LeagueRoster(league: "MLB", teams: ["Yankees", "Red Sox", "Dodgers", "Giants", "Cubs", "Cardinals", "Astros", "Braves", "Mets", "Phillies", "Padres", "Mariners", "Rangers", "Twins", "Orioles"]),
    ]

    static let hockeyLeagues: [LeagueRoster] = [
        LeagueRoster(league: "NHL", teams: ["Maple Leafs", "Canadiens", "Bruins", "Rangers", "Penguins", "Blackhawks", "Red Wings", "Oilers", "Flames", "Canucks", "Golden Knights", "Avalanche", "Lightning", "Panthers", "Capitals"]),
        LeagueRoster(league: "KHL", teams: ["CSKA Moscow", "SKA", "Dynamo Moscow", "Ak Bars", "Avangard", "Lokomotiv", "Salavat Yulaev", "Metallurg", "Sibir", "Torpedo"]),
    ]

    static let esportsLeagues: [LeagueRoster] = [
        LeagueRoster(league: "CS2", teams: ["Natus Vincere", "Vitality", "G2", "FaZe", "Spirit", "MOUZ", "Complexity", "Heroic", "Cloud9", "Liquid"]),
        LeagueRoster(league: "LoL", teams: ["T1", "Gen.G", "JD Gaming", "Bilibili Gaming", "G2 Esports", "Fnatic", "Cloud9 LoL", "Team Liquid LoL", "Hanwha Life", "Dplus KIA"]),
        LeagueRoster(league: "Dota 2", teams: ["Team Spirit", "OG", "Team Liquid", "PSG.LGD", "Xtreme Gaming", "Entity", "Gaimin Gladiators", "Tundra", "Falcons", "Aurora"]),
    ]

    static func leagues(for sport: Sport) -> [LeagueRoster] {
        switch sport {
        case .soccer: return soccerLeagues
        case .basketball: return basketballLeagues
        case .tennis: return tennisLeagues
        case .baseball: return baseballLeagues
        case .hockey: return hockeyLeagues
        case .esports: return esportsLeagues
        }
    }

    static func teams(for sport: Sport) -> [String] {
        leagues(for: sport).flatMap(\.teams)
    }

    static func randomPair(for sport: Sport) -> (home: String, away: String, league: String) {
        let roster = leagues(for: sport).randomElement()!
        let shuffled = roster.teams.shuffled()
        return (shuffled[0], shuffled[1], roster.league)
    }

    static func venue(for sport: Sport) -> String {
        switch sport {
        case .soccer: return ["Emirates Stadium", "Old Trafford", "Anfield", "Etihad Stadium", "Santiago Bernabeu", "Camp Nou", "San Siro", "Allianz Arena", "Signal Iduna Park", "Stamford Bridge"].randomElement()!
        case .basketball: return ["Crypto.com Arena", "Chase Center", "TD Garden", "Barclays Center", "Ball Arena", "Footprint Center", "Madison Square Garden", "United Center"].randomElement()!
        case .tennis: return ["Centre Court", "Rod Laver Arena", "Arthur Ashe Stadium", "Philippe Chatrier", "Court Philippe-Chatrier", "Louis Armstrong Stadium"].randomElement()!
        case .baseball: return ["Yankee Stadium", "Fenway Park", "Dodger Stadium", "Wrigley Field", "Oracle Park", "Minute Maid Park"].randomElement()!
        case .hockey: return ["Scotiabank Arena", "Bell Centre", "TD Garden", "Madison Square Garden", "Rogers Arena", "Ball Arena"].randomElement()!
        case .esports: return ["BLAST Arena", "ESL Studio", "LoL Park", "Mercedes-Benz Arena", "O2 Arena", "Intel Extreme Masters Stage"].randomElement()!
        }
    }
}


extension TeamCatalog {
    static var allTeamNames: [String] {
        Sport.allCases.flatMap { teams(for: $0) }
    }

    static func sport(forTeam name: String) -> Sport? {
        for sport in Sport.allCases {
            if teams(for: sport).contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) {
                return sport
            }
        }
        return nil
    }

    static func league(forTeam name: String, sport: Sport) -> String? {
        for roster in leagues(for: sport) {
            if roster.teams.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) {
                return roster.league
            }
        }
        return nil
    }

    static func searchTeams(query: String, limit: Int = 20) -> [String] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return Array(allTeamNames.prefix(limit)) }
        return allTeamNames
            .filter { $0.localizedCaseInsensitiveContains(q) }
            .sorted()
            .prefix(limit)
            .map { $0 }
    }
}

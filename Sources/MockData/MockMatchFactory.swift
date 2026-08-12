import Foundation
import SwiftData

enum MockMatchFactory {
    private static let hour: TimeInterval = 3600
    private static let day: TimeInterval = 86400

    static func seedMatches(into context: ModelContext) {
        let templates = makeTemplates()
        for template in templates {
            context.insert(template)
        }
        try? context.save()
    }

    static func makeTemplates(now: Date = Date()) -> [Match] {
        var matches: [Match] = []
        matches.append(contentsOf: soccerFixtures(now: now))
        matches.append(contentsOf: basketballFixtures(now: now))
        matches.append(contentsOf: tennisFixtures(now: now))
        matches.append(contentsOf: baseballFixtures(now: now))
        matches.append(contentsOf: hockeyFixtures(now: now))
        matches.append(contentsOf: esportsFixtures(now: now))
        matches.append(contentsOf: generatedDepthFixtures(now: now))
        return matches
    }

    /// Extra generated slate so the feed feels dense across days and leagues.
    private static func generatedDepthFixtures(now: Date) -> [Match] {
        var output: [Match] = []
        let sports = Sport.allCases
        for (sportIndex, sport) in sports.enumerated() {
            let rosters = TeamCatalog.leagues(for: sport)
            guard let roster = rosters.first, roster.teams.count >= 4 else { continue }
            let teams = roster.teams
            var pairIndex = 0
            for dayOffset in 0..<8 {
                for slot in 0..<4 {
                    let home = teams[(pairIndex * 2) % teams.count]
                    let away = teams[(pairIndex * 2 + 1) % teams.count]
                    pairIndex += 1
                    if home == away { continue }
                    let hours = Double(dayOffset * 24 + slot * 5 + sportIndex)
                    let status: MatchStatus
                    let minute: Int
                    var homeScore = 0
                    var awayScore = 0
                    if dayOffset == 0 && slot == 0 {
                        status = .live
                        minute = 20 + sportIndex * 3
                        homeScore = Int.random(in: 0...2)
                        awayScore = Int.random(in: 0...2)
                    } else if dayOffset == 0 && slot == 1 {
                        status = .upcoming
                        minute = 0
                    } else if dayOffset >= 4 {
                        status = .finished
                        minute = sport == .soccer || sport == .hockey ? 90 : 48
                        homeScore = Int.random(in: 0...4)
                        awayScore = Int.random(in: 0...4)
                    } else {
                        status = .upcoming
                        minute = 0
                    }
                    let priced = TeamCatalog.fairOdds(home: home, away: away, allowDraw: sport.allowsDraw)
                    output.append(
                        Match(
                            homeTeam: home,
                            awayTeam: away,
                            date: now.addingTimeInterval(hours * hour - (status == .finished ? day * 2 : 0)),
                            sport: sport,
                            status: status,
                            homeOdds: priced.home,
                            awayOdds: priced.away,
                            drawOdds: priced.draw,
                            homeScore: homeScore,
                            awayScore: awayScore,
                            league: roster.league,
                            venue: TeamCatalog.venue(for: sport),
                            minute: minute,
                            isFeatured: slot == 0 && dayOffset == 1,
                            popularity: 40 + ((sportIndex * 7 + dayOffset * 5 + slot * 3) % 55)
                        )
                    )
                }
            }
        }
        return output
    }

    private static func soccerFixtures(now: Date) -> [Match] {
        [
            Match(homeTeam: "Arsenal", awayTeam: "Chelsea", date: now.addingTimeInterval(-5400.0), sport: .soccer, status: .live, homeOdds: 2.15, awayOdds: 3.4, drawOdds: 3.2, homeScore: 1, awayScore: 1, league: "Premier League", venue: "Emirates Stadium", minute: 67, isFeatured: true, popularity: 98),
            Match(homeTeam: "Liverpool", awayTeam: "Manchester City", date: now.addingTimeInterval(7200), sport: .soccer, status: .upcoming, homeOdds: 2.45, awayOdds: 2.8, drawOdds: 3.3, homeScore: 0, awayScore: 0, league: "Premier League", venue: "Anfield", minute: 0, isFeatured: true, popularity: 99),
            Match(homeTeam: "Real Madrid", awayTeam: "Barcelona", date: now.addingTimeInterval(-2880.0), sport: .soccer, status: .live, homeOdds: 2.3, awayOdds: 2.9, drawOdds: 3.4, homeScore: 2, awayScore: 1, league: "La Liga", venue: "Santiago Bernabeu", minute: 54, isFeatured: true, popularity: 97),
            Match(homeTeam: "Bayern Munich", awayTeam: "Borussia Dortmund", date: now.addingTimeInterval(18000), sport: .soccer, status: .upcoming, homeOdds: 1.85, awayOdds: 3.9, drawOdds: 3.6, homeScore: 0, awayScore: 0, league: "Bundesliga", venue: "Allianz Arena", minute: 0, isFeatured: true, popularity: 94),
            Match(homeTeam: "Inter", awayTeam: "AC Milan", date: now.addingTimeInterval(-93600), sport: .soccer, status: .finished, homeOdds: 2.1, awayOdds: 3.5, drawOdds: 3.2, homeScore: 2, awayScore: 0, league: "Serie A", venue: "San Siro", minute: 90, isFeatured: false, popularity: 90),
            Match(homeTeam: "Tottenham", awayTeam: "Newcastle", date: now.addingTimeInterval(28800), sport: .soccer, status: .upcoming, homeOdds: 2.2, awayOdds: 3.3, drawOdds: 3.25, homeScore: 0, awayScore: 0, league: "Premier League", venue: "Tottenham Hotspur Stadium", minute: 0, isFeatured: false, popularity: 82),
            Match(homeTeam: "Atletico Madrid", awayTeam: "Sevilla", date: now.addingTimeInterval(-10800), sport: .soccer, status: .live, homeOdds: 1.95, awayOdds: 3.8, drawOdds: 3.4, homeScore: 1, awayScore: 0, league: "La Liga", venue: "Wanda Metropolitano", minute: 33, isFeatured: false, popularity: 78),
            Match(homeTeam: "Juventus", awayTeam: "Napoli", date: now.addingTimeInterval(108000), sport: .soccer, status: .upcoming, homeOdds: 2.55, awayOdds: 2.75, drawOdds: 3.15, homeScore: 0, awayScore: 0, league: "Serie A", venue: "Allianz Stadium", minute: 0, isFeatured: false, popularity: 85),
            Match(homeTeam: "RB Leipzig", awayTeam: "Bayer Leverkusen", date: now.addingTimeInterval(-180000), sport: .soccer, status: .finished, homeOdds: 2.6, awayOdds: 2.65, drawOdds: 3.4, homeScore: 1, awayScore: 2, league: "Bundesliga", venue: "Red Bull Arena", minute: 90, isFeatured: false, popularity: 70),
            Match(homeTeam: "Manchester United", awayTeam: "Aston Villa", date: now.addingTimeInterval(43200), sport: .soccer, status: .upcoming, homeOdds: 2.05, awayOdds: 3.55, drawOdds: 3.4, homeScore: 0, awayScore: 0, league: "Premier League", venue: "Old Trafford", minute: 0, isFeatured: false, popularity: 88),
            Match(homeTeam: "Villarreal", awayTeam: "Real Sociedad", date: now.addingTimeInterval(72000), sport: .soccer, status: .upcoming, homeOdds: 2.4, awayOdds: 2.95, drawOdds: 3.2, homeScore: 0, awayScore: 0, league: "La Liga", venue: "Estadio de la Ceramica", minute: 0, isFeatured: false, popularity: 65),
            Match(homeTeam: "Roma", awayTeam: "Lazio", date: now.addingTimeInterval(-21600), sport: .soccer, status: .live, homeOdds: 2.7, awayOdds: 2.6, drawOdds: 3.1, homeScore: 0, awayScore: 0, league: "Serie A", venue: "Stadio Olimpico", minute: 12, isFeatured: true, popularity: 91),
            Match(homeTeam: "Brighton", awayTeam: "West Ham", date: now.addingTimeInterval(-172800), sport: .soccer, status: .finished, homeOdds: 2.25, awayOdds: 3.2, drawOdds: 3.3, homeScore: 3, awayScore: 1, league: "Premier League", venue: "Amex Stadium", minute: 90, isFeatured: false, popularity: 60),
            Match(homeTeam: "Athletic Bilbao", awayTeam: "Betis", date: now.addingTimeInterval(129600), sport: .soccer, status: .upcoming, homeOdds: 2.15, awayOdds: 3.45, drawOdds: 3.25, homeScore: 0, awayScore: 0, league: "La Liga", venue: "San Mames", minute: 0, isFeatured: false, popularity: 58),
            Match(homeTeam: "Atalanta", awayTeam: "Fiorentina", date: now.addingTimeInterval(-259200), sport: .soccer, status: .finished, homeOdds: 1.9, awayOdds: 4.0, drawOdds: 3.5, homeScore: 2, awayScore: 2, league: "Serie A", venue: "Gewiss Stadium", minute: 90, isFeatured: false, popularity: 55),
            Match(homeTeam: "Wolfsburg", awayTeam: "Freiburg", date: now.addingTimeInterval(50400), sport: .soccer, status: .upcoming, homeOdds: 2.35, awayOdds: 3.1, drawOdds: 3.25, homeScore: 0, awayScore: 0, league: "Bundesliga", venue: "Volkswagen Arena", minute: 0, isFeatured: false, popularity: 50),
            Match(homeTeam: "Fulham", awayTeam: "Brentford", date: now.addingTimeInterval(-7920.000000000001), sport: .soccer, status: .live, homeOdds: 2.5, awayOdds: 2.9, drawOdds: 3.2, homeScore: 0, awayScore: 1, league: "Premier League", venue: "Craven Cottage", minute: 41, isFeatured: false, popularity: 72),
            Match(homeTeam: "Girona", awayTeam: "Osasuna", date: now.addingTimeInterval(172800), sport: .soccer, status: .upcoming, homeOdds: 2.05, awayOdds: 3.7, drawOdds: 3.35, homeScore: 0, awayScore: 0, league: "La Liga", venue: "Montilivi", minute: 0, isFeatured: false, popularity: 48),
            Match(homeTeam: "Bologna", awayTeam: "Torino", date: now.addingTimeInterval(-345600), sport: .soccer, status: .finished, homeOdds: 2.2, awayOdds: 3.3, drawOdds: 3.2, homeScore: 1, awayScore: 0, league: "Serie A", venue: "Renato Dall'Ara", minute: 90, isFeatured: false, popularity: 45),
            Match(homeTeam: "Stuttgart", awayTeam: "Hoffenheim", date: now.addingTimeInterval(32400), sport: .soccer, status: .upcoming, homeOdds: 2.1, awayOdds: 3.5, drawOdds: 3.4, homeScore: 0, awayScore: 0, league: "Bundesliga", venue: "Mercedes-Benz Arena", minute: 0, isFeatured: false, popularity: 52),
            Match(homeTeam: "Crystal Palace", awayTeam: "Wolves", date: now.addingTimeInterval(93600), sport: .soccer, status: .upcoming, homeOdds: 2.45, awayOdds: 3.0, drawOdds: 3.2, homeScore: 0, awayScore: 0, league: "Premier League", venue: "Selhurst Park", minute: 0, isFeatured: false, popularity: 47),
            Match(homeTeam: "Valencia", awayTeam: "Mallorca", date: now.addingTimeInterval(-144000), sport: .soccer, status: .finished, homeOdds: 2.3, awayOdds: 3.2, drawOdds: 3.15, homeScore: 0, awayScore: 0, league: "La Liga", venue: "Mestalla", minute: 90, isFeatured: false, popularity: 40),
            Match(homeTeam: "Napoli", awayTeam: "Atalanta", date: now.addingTimeInterval(64800), sport: .soccer, status: .upcoming, homeOdds: 2.0, awayOdds: 3.6, drawOdds: 3.4, homeScore: 0, awayScore: 0, league: "Serie A", venue: "Diego Armando Maradona", minute: 0, isFeatured: true, popularity: 86),
            Match(homeTeam: "Eintracht Frankfurt", awayTeam: "Gladbach", date: now.addingTimeInterval(-14400), sport: .soccer, status: .live, homeOdds: 2.25, awayOdds: 3.25, drawOdds: 3.3, homeScore: 2, awayScore: 2, league: "Bundesliga", venue: "Deutsche Bank Park", minute: 78, isFeatured: false, popularity: 68),
            Match(homeTeam: "Everton", awayTeam: "Nottingham Forest", date: now.addingTimeInterval(151200), sport: .soccer, status: .upcoming, homeOdds: 2.6, awayOdds: 2.7, drawOdds: 3.2, homeScore: 0, awayScore: 0, league: "Premier League", venue: "Goodison Park", minute: 0, isFeatured: false, popularity: 44),
            Match(homeTeam: "Celta Vigo", awayTeam: "Getafe", date: now.addingTimeInterval(-54000), sport: .soccer, status: .finished, homeOdds: 2.4, awayOdds: 3.1, drawOdds: 3.15, homeScore: 1, awayScore: 1, league: "La Liga", venue: "Balaidos", minute: 90, isFeatured: false, popularity: 36),
            Match(homeTeam: "Lazio", awayTeam: "Bologna", date: now.addingTimeInterval(21600), sport: .soccer, status: .upcoming, homeOdds: 1.95, awayOdds: 3.85, drawOdds: 3.45, homeScore: 0, awayScore: 0, league: "Serie A", venue: "Stadio Olimpico", minute: 0, isFeatured: false, popularity: 57),
            Match(homeTeam: "Mainz", awayTeam: "Augsburg", date: now.addingTimeInterval(194400), sport: .soccer, status: .upcoming, homeOdds: 2.35, awayOdds: 3.15, drawOdds: 3.2, homeScore: 0, awayScore: 0, league: "Bundesliga", venue: "MEWA Arena", minute: 0, isFeatured: false, popularity: 33),
            Match(homeTeam: "Bournemouth", awayTeam: "Leicester", date: now.addingTimeInterval(-234000), sport: .soccer, status: .finished, homeOdds: 2.15, awayOdds: 3.4, drawOdds: 3.3, homeScore: 2, awayScore: 1, league: "Premier League", venue: "Vitality Stadium", minute: 90, isFeatured: false, popularity: 42),
            Match(homeTeam: "Barcelona", awayTeam: "Girona", date: now.addingTimeInterval(79200), sport: .soccer, status: .upcoming, homeOdds: 1.55, awayOdds: 5.5, drawOdds: 4.2, homeScore: 0, awayScore: 0, league: "La Liga", venue: "Camp Nou", minute: 0, isFeatured: true, popularity: 93),
        ]
    }

    private static func basketballFixtures(now: Date) -> [Match] {
        [
            Match(homeTeam: "Lakers", awayTeam: "Warriors", date: now.addingTimeInterval(-1800.0), sport: .basketball, status: .live, homeOdds: 1.9, awayOdds: 1.95, homeScore: 88, awayScore: 92, league: "NBA", venue: "Crypto.com Arena", minute: 36, isFeatured: true, popularity: 96),
            Match(homeTeam: "Celtics", awayTeam: "Heat", date: now.addingTimeInterval(10800), sport: .basketball, status: .upcoming, homeOdds: 1.7, awayOdds: 2.2, homeScore: 0, awayScore: 0, league: "NBA", venue: "TD Garden", minute: 0, isFeatured: true, popularity: 92),
            Match(homeTeam: "Bucks", awayTeam: "Nets", date: now.addingTimeInterval(-100800), sport: .basketball, status: .finished, homeOdds: 1.85, awayOdds: 2.0, homeScore: 112, awayScore: 105, league: "NBA", venue: "Fiserv Forum", minute: 48, isFeatured: false, popularity: 80),
            Match(homeTeam: "Suns", awayTeam: "Nuggets", date: now.addingTimeInterval(36000), sport: .basketball, status: .upcoming, homeOdds: 2.05, awayOdds: 1.8, homeScore: 0, awayScore: 0, league: "NBA", venue: "Footprint Center", minute: 0, isFeatured: false, popularity: 88),
            Match(homeTeam: "Mavericks", awayTeam: "Clippers", date: now.addingTimeInterval(-7200), sport: .basketball, status: .live, homeOdds: 1.95, awayOdds: 1.9, homeScore: 64, awayScore: 61, league: "NBA", venue: "American Airlines Center", minute: 24, isFeatured: true, popularity: 90),
            Match(homeTeam: "Knicks", awayTeam: "76ers", date: now.addingTimeInterval(108000), sport: .basketball, status: .upcoming, homeOdds: 2.1, awayOdds: 1.78, homeScore: 0, awayScore: 0, league: "NBA", venue: "Madison Square Garden", minute: 0, isFeatured: false, popularity: 85),
            Match(homeTeam: "Bulls", awayTeam: "Cavaliers", date: now.addingTimeInterval(-180000), sport: .basketball, status: .finished, homeOdds: 2.2, awayOdds: 1.7, homeScore: 98, awayScore: 110, league: "NBA", venue: "United Center", minute: 48, isFeatured: false, popularity: 70),
            Match(homeTeam: "Kings", awayTeam: "Grizzlies", date: now.addingTimeInterval(57600), sport: .basketball, status: .upcoming, homeOdds: 1.88, awayOdds: 1.97, homeScore: 0, awayScore: 0, league: "NBA", venue: "Golden 1 Center", minute: 0, isFeatured: false, popularity: 65),
            Match(homeTeam: "Timberwolves", awayTeam: "Thunder", date: now.addingTimeInterval(-12600.0), sport: .basketball, status: .live, homeOdds: 1.82, awayOdds: 2.05, homeScore: 71, awayScore: 68, league: "NBA", venue: "Target Center", minute: 30, isFeatured: false, popularity: 78),
            Match(homeTeam: "Pacers", awayTeam: "Pelicans", date: now.addingTimeInterval(144000), sport: .basketball, status: .upcoming, homeOdds: 1.92, awayOdds: 1.93, homeScore: 0, awayScore: 0, league: "NBA", venue: "Gainbridge Fieldhouse", minute: 0, isFeatured: false, popularity: 60),
            Match(homeTeam: "Real Madrid BB", awayTeam: "Barcelona BB", date: now.addingTimeInterval(28800), sport: .basketball, status: .upcoming, homeOdds: 1.85, awayOdds: 2.0, homeScore: 0, awayScore: 0, league: "EuroLeague", venue: "WiZink Center", minute: 0, isFeatured: false, popularity: 72),
            Match(homeTeam: "Olympiacos", awayTeam: "Panathinaikos", date: now.addingTimeInterval(-162000), sport: .basketball, status: .finished, homeOdds: 1.9, awayOdds: 1.95, homeScore: 78, awayScore: 74, league: "EuroLeague", venue: "Peace and Friendship Stadium", minute: 40, isFeatured: true, popularity: 84),
            Match(homeTeam: "Fenerbahce", awayTeam: "Efes", date: now.addingTimeInterval(72000), sport: .basketball, status: .upcoming, homeOdds: 1.75, awayOdds: 2.15, homeScore: 0, awayScore: 0, league: "EuroLeague", venue: "Ulker Sports Arena", minute: 0, isFeatured: false, popularity: 58),
            Match(homeTeam: "Zalgiris", awayTeam: "Bayern Munich BB", date: now.addingTimeInterval(-3600), sport: .basketball, status: .live, homeOdds: 2.05, awayOdds: 1.8, homeScore: 42, awayScore: 39, league: "EuroLeague", venue: "Zalgirio Arena", minute: 18, isFeatured: false, popularity: 55),
            Match(homeTeam: "Maccabi Tel Aviv", awayTeam: "CSKA", date: now.addingTimeInterval(187200), sport: .basketball, status: .upcoming, homeOdds: 2.1, awayOdds: 1.78, homeScore: 0, awayScore: 0, league: "EuroLeague", venue: "Menora Mivtachim Arena", minute: 0, isFeatured: false, popularity: 50),
        ]
    }

    private static func tennisFixtures(now: Date) -> [Match] {
        [
            Match(homeTeam: "Djokovic", awayTeam: "Alcaraz", date: now.addingTimeInterval(-4320.0), sport: .tennis, status: .live, homeOdds: 2.1, awayOdds: 1.8, homeScore: 1, awayScore: 2, league: "ATP", venue: "Centre Court", minute: 55, isFeatured: true, popularity: 97),
            Match(homeTeam: "Sinner", awayTeam: "Medvedev", date: now.addingTimeInterval(14400), sport: .tennis, status: .upcoming, homeOdds: 1.65, awayOdds: 2.3, homeScore: 0, awayScore: 0, league: "ATP", venue: "Rod Laver Arena", minute: 0, isFeatured: true, popularity: 93),
            Match(homeTeam: "Zverev", awayTeam: "Tsitsipas", date: now.addingTimeInterval(-108000), sport: .tennis, status: .finished, homeOdds: 1.9, awayOdds: 1.95, homeScore: 3, awayScore: 1, league: "ATP", venue: "Arthur Ashe Stadium", minute: 90, isFeatured: false, popularity: 75),
            Match(homeTeam: "Swiatek", awayTeam: "Sabalenka", date: now.addingTimeInterval(32400), sport: .tennis, status: .upcoming, homeOdds: 1.85, awayOdds: 2.0, homeScore: 0, awayScore: 0, league: "WTA", venue: "Philippe Chatrier", minute: 0, isFeatured: true, popularity: 90),
            Match(homeTeam: "Gauff", awayTeam: "Rybakina", date: now.addingTimeInterval(-9000.0), sport: .tennis, status: .live, homeOdds: 2.05, awayOdds: 1.82, homeScore: 1, awayScore: 1, league: "WTA", venue: "Louis Armstrong Stadium", minute: 40, isFeatured: false, popularity: 82),
            Match(homeTeam: "Ruud", awayTeam: "Rublev", date: now.addingTimeInterval(93600), sport: .tennis, status: .upcoming, homeOdds: 2.15, awayOdds: 1.75, homeScore: 0, awayScore: 0, league: "ATP", venue: "Centre Court", minute: 0, isFeatured: false, popularity: 68),
            Match(homeTeam: "Pegula", awayTeam: "Jabeur", date: now.addingTimeInterval(-198000), sport: .tennis, status: .finished, homeOdds: 1.7, awayOdds: 2.2, homeScore: 2, awayScore: 0, league: "WTA", venue: "Court 1", minute: 90, isFeatured: false, popularity: 60),
            Match(homeTeam: "Fritz", awayTeam: "Tiafoe", date: now.addingTimeInterval(50400), sport: .tennis, status: .upcoming, homeOdds: 1.95, awayOdds: 1.9, homeScore: 0, awayScore: 0, league: "ATP", venue: "Stadium Court", minute: 0, isFeatured: false, popularity: 70),
            Match(homeTeam: "Rune", awayTeam: "Hurkacz", date: now.addingTimeInterval(-14400), sport: .tennis, status: .live, homeOdds: 2.0, awayOdds: 1.88, homeScore: 2, awayScore: 1, league: "ATP", venue: "Grandstand", minute: 70, isFeatured: false, popularity: 66),
            Match(homeTeam: "Keys", awayTeam: "Bencic", date: now.addingTimeInterval(129600), sport: .tennis, status: .upcoming, homeOdds: 1.78, awayOdds: 2.1, homeScore: 0, awayScore: 0, league: "WTA", venue: "Court 7", minute: 0, isFeatured: false, popularity: 58),
        ]
    }

    private static func baseballFixtures(now: Date) -> [Match] {
        [
            Match(homeTeam: "Yankees", awayTeam: "Red Sox", date: now.addingTimeInterval(-3600), sport: .baseball, status: .live, homeOdds: 1.85, awayOdds: 2.05, homeScore: 3, awayScore: 2, league: "MLB", venue: "Yankee Stadium", minute: 6, isFeatured: true, popularity: 94),
            Match(homeTeam: "Dodgers", awayTeam: "Giants", date: now.addingTimeInterval(18000), sport: .baseball, status: .upcoming, homeOdds: 1.7, awayOdds: 2.2, homeScore: 0, awayScore: 0, league: "MLB", venue: "Dodger Stadium", minute: 0, isFeatured: true, popularity: 91),
            Match(homeTeam: "Cubs", awayTeam: "Cardinals", date: now.addingTimeInterval(-144000), sport: .baseball, status: .finished, homeOdds: 1.95, awayOdds: 1.9, homeScore: 5, awayScore: 3, league: "MLB", venue: "Wrigley Field", minute: 9, isFeatured: false, popularity: 77),
            Match(homeTeam: "Astros", awayTeam: "Braves", date: now.addingTimeInterval(43200), sport: .baseball, status: .upcoming, homeOdds: 1.88, awayOdds: 1.97, homeScore: 0, awayScore: 0, league: "MLB", venue: "Minute Maid Park", minute: 0, isFeatured: false, popularity: 80),
            Match(homeTeam: "Mets", awayTeam: "Phillies", date: now.addingTimeInterval(-10800), sport: .baseball, status: .live, homeOdds: 2.05, awayOdds: 1.82, homeScore: 1, awayScore: 4, league: "MLB", venue: "Citi Field", minute: 5, isFeatured: false, popularity: 85),
            Match(homeTeam: "Padres", awayTeam: "Mariners", date: now.addingTimeInterval(100800), sport: .baseball, status: .upcoming, homeOdds: 1.92, awayOdds: 1.93, homeScore: 0, awayScore: 0, league: "MLB", venue: "Petco Park", minute: 0, isFeatured: false, popularity: 65),
            Match(homeTeam: "Rangers", awayTeam: "Twins", date: now.addingTimeInterval(-252000), sport: .baseball, status: .finished, homeOdds: 1.8, awayOdds: 2.1, homeScore: 2, awayScore: 6, league: "MLB", venue: "Globe Life Field", minute: 9, isFeatured: false, popularity: 55),
            Match(homeTeam: "Orioles", awayTeam: "Yankees", date: now.addingTimeInterval(64800), sport: .baseball, status: .upcoming, homeOdds: 2.15, awayOdds: 1.75, homeScore: 0, awayScore: 0, league: "MLB", venue: "Camden Yards", minute: 0, isFeatured: false, popularity: 72),
        ]
    }

    private static func hockeyFixtures(now: Date) -> [Match] {
        [
            Match(homeTeam: "Maple Leafs", awayTeam: "Canadiens", date: now.addingTimeInterval(-2520.0), sport: .hockey, status: .live, homeOdds: 2.05, awayOdds: 3.2, drawOdds: 3.4, homeScore: 2, awayScore: 1, league: "NHL", venue: "Scotiabank Arena", minute: 34, isFeatured: true, popularity: 95),
            Match(homeTeam: "Bruins", awayTeam: "Rangers", date: now.addingTimeInterval(21600), sport: .hockey, status: .upcoming, homeOdds: 1.95, awayOdds: 3.4, drawOdds: 3.5, homeScore: 0, awayScore: 0, league: "NHL", venue: "TD Garden", minute: 0, isFeatured: true, popularity: 90),
            Match(homeTeam: "Penguins", awayTeam: "Capitals", date: now.addingTimeInterval(-126000), sport: .hockey, status: .finished, homeOdds: 2.2, awayOdds: 2.95, drawOdds: 3.3, homeScore: 3, awayScore: 2, league: "NHL", venue: "PPG Paints Arena", minute: 60, isFeatured: false, popularity: 78),
            Match(homeTeam: "Oilers", awayTeam: "Flames", date: now.addingTimeInterval(-7200), sport: .hockey, status: .live, homeOdds: 1.85, awayOdds: 3.6, drawOdds: 3.7, homeScore: 1, awayScore: 1, league: "NHL", venue: "Rogers Place", minute: 18, isFeatured: true, popularity: 88),
            Match(homeTeam: "Canucks", awayTeam: "Golden Knights", date: now.addingTimeInterval(79200), sport: .hockey, status: .upcoming, homeOdds: 2.3, awayOdds: 2.8, drawOdds: 3.25, homeScore: 0, awayScore: 0, league: "NHL", venue: "Rogers Arena", minute: 0, isFeatured: false, popularity: 74),
            Match(homeTeam: "Avalanche", awayTeam: "Lightning", date: now.addingTimeInterval(-216000), sport: .hockey, status: .finished, homeOdds: 2.1, awayOdds: 3.1, drawOdds: 3.35, homeScore: 4, awayScore: 1, league: "NHL", venue: "Ball Arena", minute: 60, isFeatured: false, popularity: 70),
            Match(homeTeam: "Panthers", awayTeam: "Red Wings", date: now.addingTimeInterval(36000), sport: .hockey, status: .upcoming, homeOdds: 1.9, awayOdds: 3.5, drawOdds: 3.55, homeScore: 0, awayScore: 0, league: "NHL", venue: "Amerant Bank Arena", minute: 0, isFeatured: false, popularity: 66),
            Match(homeTeam: "CSKA Moscow", awayTeam: "SKA", date: now.addingTimeInterval(108000), sport: .hockey, status: .upcoming, homeOdds: 2.15, awayOdds: 3.0, drawOdds: 3.2, homeScore: 0, awayScore: 0, league: "KHL", venue: "CSKA Arena", minute: 0, isFeatured: false, popularity: 60),
            Match(homeTeam: "Dynamo Moscow", awayTeam: "Ak Bars", date: now.addingTimeInterval(-16200.0), sport: .hockey, status: .live, homeOdds: 2.25, awayOdds: 2.9, drawOdds: 3.15, homeScore: 0, awayScore: 2, league: "KHL", venue: "VTB Arena", minute: 41, isFeatured: false, popularity: 58),
            Match(homeTeam: "Avangard", awayTeam: "Lokomotiv", date: now.addingTimeInterval(-288000), sport: .hockey, status: .finished, homeOdds: 2.05, awayOdds: 3.15, drawOdds: 3.25, homeScore: 1, awayScore: 0, league: "KHL", venue: "G-Drive Arena", minute: 60, isFeatured: false, popularity: 50),
        ]
    }

    private static func esportsFixtures(now: Date) -> [Match] {
        [
            Match(homeTeam: "Natus Vincere", awayTeam: "Vitality", date: now.addingTimeInterval(-1440.0), sport: .esports, status: .live, homeOdds: 1.75, awayOdds: 2.15, homeScore: 1, awayScore: 1, league: "CS2", venue: "BLAST Arena", minute: 22, isFeatured: true, popularity: 96),
            Match(homeTeam: "G2", awayTeam: "FaZe", date: now.addingTimeInterval(25200), sport: .esports, status: .upcoming, homeOdds: 1.9, awayOdds: 1.95, homeScore: 0, awayScore: 0, league: "CS2", venue: "ESL Studio", minute: 0, isFeatured: true, popularity: 92),
            Match(homeTeam: "T1", awayTeam: "Gen.G", date: now.addingTimeInterval(-5400.0), sport: .esports, status: .live, homeOdds: 1.85, awayOdds: 2.0, homeScore: 0, awayScore: 1, league: "LoL", venue: "LoL Park", minute: 28, isFeatured: true, popularity: 98),
            Match(homeTeam: "JD Gaming", awayTeam: "Bilibili Gaming", date: now.addingTimeInterval(-172800), sport: .esports, status: .finished, homeOdds: 1.7, awayOdds: 2.2, homeScore: 2, awayScore: 0, league: "LoL", venue: "Mercedes-Benz Arena", minute: 40, isFeatured: false, popularity: 80),
            Match(homeTeam: "Team Spirit", awayTeam: "OG", date: now.addingTimeInterval(14400), sport: .esports, status: .upcoming, homeOdds: 1.65, awayOdds: 2.3, homeScore: 0, awayScore: 0, league: "Dota 2", venue: "O2 Arena", minute: 0, isFeatured: true, popularity: 90),
            Match(homeTeam: "PSG.LGD", awayTeam: "Xtreme Gaming", date: now.addingTimeInterval(-10800), sport: .esports, status: .live, homeOdds: 2.05, awayOdds: 1.8, homeScore: 1, awayScore: 0, league: "Dota 2", venue: "Intel Extreme Masters Stage", minute: 35, isFeatured: false, popularity: 78),
            Match(homeTeam: "MOUZ", awayTeam: "Complexity", date: now.addingTimeInterval(72000), sport: .esports, status: .upcoming, homeOdds: 1.88, awayOdds: 1.97, homeScore: 0, awayScore: 0, league: "CS2", venue: "BLAST Arena", minute: 0, isFeatured: false, popularity: 70),
            Match(homeTeam: "Fnatic", awayTeam: "Cloud9 LoL", date: now.addingTimeInterval(115200), sport: .esports, status: .upcoming, homeOdds: 2.1, awayOdds: 1.78, homeScore: 0, awayScore: 0, league: "LoL", venue: "LoL Park", minute: 0, isFeatured: false, popularity: 65),
            Match(homeTeam: "BetBoom", awayTeam: "Gaimin Gladiators", date: now.addingTimeInterval(-198000), sport: .esports, status: .finished, homeOdds: 1.95, awayOdds: 1.9, homeScore: 2, awayScore: 1, league: "Dota 2", venue: "ESL Studio", minute: 50, isFeatured: false, popularity: 60),
            Match(homeTeam: "Spirit", awayTeam: "Heroic", date: now.addingTimeInterval(-259200), sport: .esports, status: .finished, homeOdds: 1.8, awayOdds: 2.1, homeScore: 2, awayScore: 0, league: "CS2", venue: "BLAST Arena", minute: 40, isFeatured: false, popularity: 58),
            Match(homeTeam: "Hanwha Life", awayTeam: "Dplus KIA", date: now.addingTimeInterval(50400), sport: .esports, status: .upcoming, homeOdds: 1.92, awayOdds: 1.93, homeScore: 0, awayScore: 0, league: "LoL", venue: "LoL Park", minute: 0, isFeatured: false, popularity: 62),
            Match(homeTeam: "Tundra", awayTeam: "Falcons", date: now.addingTimeInterval(-7920.000000000001), sport: .esports, status: .live, homeOdds: 2.0, awayOdds: 1.88, homeScore: 0, awayScore: 1, league: "Dota 2", venue: "O2 Arena", minute: 18, isFeatured: false, popularity: 72),
        ]
    }

}

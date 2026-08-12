import Foundation
import SwiftData

@Model
final class Match {
    @Attribute(.unique) var id: UUID
    var homeTeam: String
    var awayTeam: String
    var homeScore: Int
    var awayScore: Int
    var date: Date
    var sportRaw: String
    var statusRaw: String
    var homeOdds: Double
    var awayOdds: Double
    var drawOdds: Double?
    var league: String
    var venue: String
    var minute: Int
    var isFeatured: Bool
    var popularity: Int

    @Relationship(deleteRule: .cascade, inverse: \Bet.match)
    var bets: [Bet]? = []

    var sport: Sport {
        get { Sport(rawValue: sportRaw) ?? .soccer }
        set { sportRaw = newValue.rawValue }
    }

    var status: MatchStatus {
        get { MatchStatus(rawValue: statusRaw) ?? .upcoming }
        set { statusRaw = newValue.rawValue }
    }

    var displayName: String {
        "\(homeTeam) vs \(awayTeam)"
    }

    var scoreLine: String {
        "\(homeScore) – \(awayScore)"
    }

    var totalGoals: Int {
        homeScore + awayScore
    }

    var clockLabel: String {
        switch status {
        case .upcoming:
            return DateFormatters.kickoff.string(from: date)
        case .live:
            return "\(minute)'"
        case .finished:
            return "FT"
        case .postponed:
            return "PPD"
        }
    }

    init(
        id: UUID = UUID(),
        homeTeam: String,
        awayTeam: String,
        date: Date,
        sport: Sport,
        status: MatchStatus,
        homeOdds: Double,
        awayOdds: Double,
        drawOdds: Double? = nil,
        homeScore: Int = 0,
        awayScore: Int = 0,
        league: String = "",
        venue: String = "",
        minute: Int = 0,
        isFeatured: Bool = false,
        popularity: Int = 50
    ) {
        self.id = id
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.date = date
        self.sportRaw = sport.rawValue
        self.statusRaw = status.rawValue
        self.homeOdds = homeOdds
        self.awayOdds = awayOdds
        self.drawOdds = drawOdds
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.league = league
        self.venue = venue
        self.minute = minute
        self.isFeatured = isFeatured
        self.popularity = popularity
    }

    func odds(for type: BetType) -> Double {
        switch type {
        case .homeWin: return homeOdds
        case .awayWin: return awayOdds
        case .draw: return drawOdds ?? 3.2
        case .over: return max(1.55, min(2.8, 2.4 - Double(totalGoals) * 0.15))
        case .under: return max(1.55, min(2.8, 1.7 + Double(totalGoals) * 0.12))
        case .bothTeamsScore: return homeScore > 0 && awayScore > 0 ? 1.65 : 1.95
        case .homeOrDraw: return OddsCalculator.combine(homeOdds, drawOdds ?? 3.2)
        case .awayOrDraw: return OddsCalculator.combine(awayOdds, drawOdds ?? 3.2)
        }
    }
}

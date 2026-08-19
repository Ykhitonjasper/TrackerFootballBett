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
    var league: String
    var venue: String
    var minute: Int
    var isFeatured: Bool
    var popularity: Int

    @Relationship(deleteRule: .cascade, inverse: \MatchPick.match)
    var picks: [MatchPick]? = []

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
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.league = league
        self.venue = venue
        self.minute = minute
        self.isFeatured = isFeatured
        self.popularity = popularity
    }

    var primaryPick: MatchPick? {
        picks?.sorted { $0.confidence > $1.confidence }.first
    }
}

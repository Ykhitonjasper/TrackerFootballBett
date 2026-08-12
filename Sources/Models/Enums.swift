import Foundation
import SwiftUI

enum Sport: String, Codable, CaseIterable, Identifiable, Hashable {
    case soccer = "Soccer"
    case basketball = "Basketball"
    case tennis = "Tennis"
    case baseball = "Baseball"
    case hockey = "Hockey"
    case esports = "Esports"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .soccer: return "soccerball"
        case .basketball: return "basketball.fill"
        case .tennis: return "tennisball.fill"
        case .baseball: return "baseball.fill"
        case .hockey: return "hockey.puck.fill"
        case .esports: return "gamecontroller.fill"
        }
    }

    var shortLabel: String {
        switch self {
        case .soccer: return "SOC"
        case .basketball: return "BKB"
        case .tennis: return "TEN"
        case .baseball: return "BSB"
        case .hockey: return "HKY"
        case .esports: return "ESP"
        }
    }

    var accentColor: Color {
        switch self {
        case .soccer: return Color(red: 0.20, green: 0.58, blue: 1.00)
        case .basketball: return Color(red: 0.98, green: 0.55, blue: 0.12)
        case .tennis: return Color(red: 0.98, green: 0.78, blue: 0.15)
        case .baseball: return Color(red: 0.85, green: 0.25, blue: 0.30)
        case .hockey: return Color(red: 0.35, green: 0.65, blue: 1.00)
        case .esports: return Color(red: 0.45, green: 0.55, blue: 1.00)
        }
    }

    var allowsDraw: Bool {
        switch self {
        case .soccer, .hockey: return true
        case .basketball, .tennis, .baseball, .esports: return false
        }
    }
}

enum MatchStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case upcoming = "Upcoming"
    case live = "Live"
    case finished = "Finished"
    case postponed = "Postponed"

    var id: String { rawValue }

    var badgeColor: Color {
        switch self {
        case .upcoming: return .secondary
        case .live: return .red
        case .finished: return .gray
        case .postponed: return .orange
        }
    }

    var isBettable: Bool {
        self == .upcoming || self == .live
    }
}

enum BetOutcome: String, Codable, CaseIterable, Identifiable, Hashable {
    case won = "Won"
    case lost = "Lost"
    case pending = "Pending"
    case void = "Void"
    case cashedOut = "Cashed Out"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .won: return AppTheme.accentBright
        case .lost: return AppTheme.danger
        case .pending: return AppTheme.highlight
        case .void: return .gray
        case .cashedOut: return AppTheme.info
        }
    }

    var isSettled: Bool {
        self != .pending
    }
}

enum BetType: String, Codable, CaseIterable, Identifiable, Hashable {
    case homeWin = "Home Win"
    case awayWin = "Away Win"
    case draw = "Draw"
    case over = "Over 2.5"
    case under = "Under 2.5"
    case bothTeamsScore = "BTTS"
    case homeOrDraw = "1X"
    case awayOrDraw = "X2"

    var id: String { rawValue }

    var shortCode: String {
        switch self {
        case .homeWin: return "1"
        case .awayWin: return "2"
        case .draw: return "X"
        case .over: return "O2.5"
        case .under: return "U2.5"
        case .bothTeamsScore: return "BTTS"
        case .homeOrDraw: return "1X"
        case .awayOrDraw: return "X2"
        }
    }

    static func marketTypes(for sport: Sport) -> [BetType] {
        var types: [BetType] = [.homeWin, .awayWin]
        if sport.allowsDraw {
            types.insert(.draw, at: 1)
            types.append(contentsOf: [.homeOrDraw, .awayOrDraw])
        }
        if sport == .soccer || sport == .hockey {
            types.append(contentsOf: [.over, .under, .bothTeamsScore])
        }
        return types
    }
}

enum FeedStatusFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case live = "Live"
    case upcoming = "Upcoming"
    case finished = "Finished"

    var id: String { rawValue }

    var matchStatus: MatchStatus? {
        switch self {
        case .all: return nil
        case .live: return .live
        case .upcoming: return .upcoming
        case .finished: return .finished
        }
    }
}

enum SortOption: String, CaseIterable, Identifiable {
    case kickoff = "Kickoff"
    case oddsLow = "Odds ↑"
    case oddsHigh = "Odds ↓"
    case popularity = "Popular"

    var id: String { rawValue }
}

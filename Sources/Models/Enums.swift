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

    var isActive: Bool {
        self == .upcoming || self == .live
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

enum PickLean: String, Codable, CaseIterable, Identifiable, Hashable {
    case home = "Home"
    case away = "Away"
    case draw = "Draw"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .home: return "1"
        case .away: return "2"
        case .draw: return "X"
        }
    }
}

enum PickMarket: String, Codable, CaseIterable, Identifiable, Hashable {
    case oneXTwo = "Match Result"
    case homeOrDraw = "Home or Draw"
    case awayOrDraw = "Away or Draw"
    case bothScore = "Both to Score"
    case overTwoFive = "Over 2.5 Goals"
    case underTwoFive = "Under 2.5 Goals"

    var id: String { rawValue }

    var title: String { rawValue }

    var codeTag: String {
        switch self {
        case .oneXTwo: return "MR"
        case .homeOrDraw: return "HD"
        case .awayOrDraw: return "AD"
        case .bothScore: return "BS"
        case .overTwoFive: return "O25"
        case .underTwoFive: return "U25"
        }
    }

    static func deskMarkets(for sport: Sport) -> [PickMarket] {
        var items: [PickMarket] = [.oneXTwo]
        if sport.allowsDraw {
            items.append(contentsOf: [.homeOrDraw, .awayOrDraw, .bothScore, .overTwoFive, .underTwoFive])
        }
        return items
    }
}

enum PickResult: String, Codable, CaseIterable, Identifiable, Hashable {
    case open = "Open"
    case hit = "Landed"
    case miss = "Missed"
    case void = "Void"

    var id: String { rawValue }
}

enum PickBoardFilter: String, CaseIterable, Identifiable {
    case today = "Today"
    case open = "Open"
    case settled = "Settled"
    case all = "All"

    var id: String { rawValue }
}

enum SortOption: String, CaseIterable, Identifiable {
    case kickoff = "Kickoff"
    case popularity = "Popular"
    case league = "League"

    var id: String { rawValue }
}

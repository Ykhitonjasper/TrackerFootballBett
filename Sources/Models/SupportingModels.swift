import Foundation
import SwiftUI

struct TimelineEvent: Identifiable, Hashable {
    let id: UUID
    let minute: Int
    let description: String
    let type: EventType
    let isHome: Bool

    enum EventType: String, Hashable, CaseIterable {
        case goal
        case yellowCard
        case redCard
        case substitution
        case corner
        case penalty
        case period
        case generic

        var icon: String {
            switch self {
            case .goal: return "soccerball"
            case .yellowCard: return "rectangle.fill"
            case .redCard: return "rectangle.fill"
            case .substitution: return "arrow.left.arrow.right"
            case .corner: return "flag.fill"
            case .penalty: return "scope"
            case .period: return "whistle.fill"
            case .generic: return "clock"
            }
        }

        var tint: Color {
            switch self {
            case .goal: return AppTheme.accentBright
            case .yellowCard: return AppTheme.highlight
            case .redCard: return AppTheme.danger
            case .substitution: return AppTheme.info
            case .corner: return AppTheme.accent
            case .penalty: return AppTheme.warning
            case .period: return .secondary
            case .generic: return .secondary
            }
        }
    }

    init(
        id: UUID = UUID(),
        minute: Int,
        description: String,
        type: EventType,
        isHome: Bool = true
    ) {
        self.id = id
        self.minute = minute
        self.description = description
        self.type = type
        self.isHome = isHome
    }

    var timeLabel: String { "\(minute)'" }
}

struct MatchStats: Hashable {
    var possessionHome: Int
    var possessionAway: Int
    var shotsHome: Int
    var shotsAway: Int
    var shotsOnTargetHome: Int
    var shotsOnTargetAway: Int
    var cornersHome: Int
    var cornersAway: Int
    var foulsHome: Int
    var foulsAway: Int
    var yellowCardsHome: Int
    var yellowCardsAway: Int
    var redCardsHome: Int
    var redCardsAway: Int
    var passesHome: Int
    var passesAway: Int

    static let empty = MatchStats(
        possessionHome: 50, possessionAway: 50,
        shotsHome: 0, shotsAway: 0,
        shotsOnTargetHome: 0, shotsOnTargetAway: 0,
        cornersHome: 0, cornersAway: 0,
        foulsHome: 0, foulsAway: 0,
        yellowCardsHome: 0, yellowCardsAway: 0,
        redCardsHome: 0, redCardsAway: 0,
        passesHome: 0, passesAway: 0
    )

    var rows: [(title: String, home: String, away: String, homeValue: Double, awayValue: Double)] {
        [
            ("Possession", "\(possessionHome)%", "\(possessionAway)%", Double(possessionHome), Double(possessionAway)),
            ("Shots", "\(shotsHome)", "\(shotsAway)", Double(shotsHome), Double(shotsAway)),
            ("On Target", "\(shotsOnTargetHome)", "\(shotsOnTargetAway)", Double(shotsOnTargetHome), Double(shotsOnTargetAway)),
            ("Corners", "\(cornersHome)", "\(cornersAway)", Double(cornersHome), Double(cornersAway)),
            ("Fouls", "\(foulsHome)", "\(foulsAway)", Double(foulsHome), Double(foulsAway)),
            ("Yellow Cards", "\(yellowCardsHome)", "\(yellowCardsAway)", Double(yellowCardsHome), Double(yellowCardsAway)),
            ("Red Cards", "\(redCardsHome)", "\(redCardsAway)", Double(redCardsHome), Double(redCardsAway)),
            ("Passes", "\(passesHome)", "\(passesAway)", Double(passesHome), Double(passesAway))
        ]
    }
}

struct AppNotification: Identifiable, Hashable {
    let id: UUID
    let title: String
    let body: String
    let date: Date
    let kind: Kind
    var isRead: Bool

    enum Kind: String, Hashable {
        case liveGoal
        case promo
        case system

        var icon: String {
            switch self {
            case .liveGoal: return "soccerball"
            case .promo: return "gift.fill"
            case .system: return "gearshape.fill"
            }
        }
    }

    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        date: Date = Date(),
        kind: Kind,
        isRead: Bool = false
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.date = date
        self.kind = kind
        self.isRead = isRead
    }
}

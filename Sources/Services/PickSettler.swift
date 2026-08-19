import Foundation
import SwiftData
import UIKit

enum PickSettler {
    static func settle(_ pick: MatchPick) {
        guard let match = pick.match else { return }
        switch match.status {
        case .postponed:
            pick.result = .void
        case .finished:
            pick.result = outcome(for: pick, match: match) ? .hit : .miss
        case .upcoming, .live:
            pick.result = .open
        }
    }

    static func settleAll(in context: ModelContext) {
        let picks = (try? context.fetch(FetchDescriptor<MatchPick>())) ?? []
        picks.forEach(settle)
    }

    private static func outcome(for pick: MatchPick, match: Match) -> Bool {
        let home = match.homeScore
        let away = match.awayScore
        switch pick.market {
        case .oneXTwo:
            switch pick.lean {
            case .home: return home > away
            case .away: return away > home
            case .draw: return home == away
            }
        case .homeOrDraw:
            return home >= away
        case .awayOrDraw:
            return away >= home
        case .bothScore:
            let yes = home > 0 && away > 0
            return pick.lean == .away ? !yes : yes
        case .overTwoFive:
            return home + away >= 3
        case .underTwoFive:
            return home + away <= 2
        }
    }
}

enum PickAnalytics {
    struct Snapshot: Hashable {
        var total: Int
        var openCount: Int
        var hitCount: Int
        var missCount: Int
        var todayCount: Int
    }

    static func snapshot(from picks: [MatchPick], now: Date = Date()) -> Snapshot {
        let calendar = Calendar.current
        return Snapshot(
            total: picks.count,
            openCount: picks.filter { $0.result == .open }.count,
            hitCount: picks.filter { $0.result == .hit }.count,
            missCount: picks.filter { $0.result == .miss }.count,
            todayCount: picks.filter { calendar.isDate($0.match?.date ?? $0.createdAt, inSameDayAs: now) }.count
        )
    }
}

enum PickClipboard {
    static func copy(_ pick: MatchPick) {
        UIPasteboard.general.string = pick.shareText
    }
}

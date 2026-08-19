import Foundation
import SwiftData

enum MockPickFactory {
    static func seedPicks(into context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<MatchPick>())) ?? []
        existing.forEach { context.delete($0) }

        let matches = (try? context.fetch(FetchDescriptor<Match>(sortBy: [SortDescriptor(\.date)]))) ?? []
        for (index, match) in matches.enumerated() where shouldWrite(match, index: index) {
            for pick in makePicks(for: match, index: index) {
                context.insert(pick)
            }
        }
        PickSettler.settleAll(in: context)
        try? context.save()
    }

    private static func shouldWrite(_ match: Match, index: Int) -> Bool {
        if match.status == .postponed { return false }
        if match.isFeatured || match.status == .live { return true }
        if match.popularity >= 55 { return true }
        return index % 2 == 0
    }

    private static func makePicks(for match: Match, index: Int) -> [MatchPick] {
        let primaryMarket = market(for: match, index: index)
        var picks = [build(match: match, index: index, market: primaryMarket, offset: 0)]
        if match.isFeatured || match.popularity >= 88, let extra = extraMarket(for: match, excluding: primaryMarket) {
            picks.append(build(match: match, index: index, market: extra, offset: 1))
        }
        return picks
    }

    private static func build(match: Match, index: Int, market: PickMarket, offset: Int) -> MatchPick {
        let lean = lean(for: match, market: market, index: index + offset)
        let confidence = min(5, max(2, 2 + match.popularity / 22 - offset))
        return MatchPick(
            lean: lean,
            market: market,
            confidence: confidence,
            headline: headline(for: match, market: market, lean: lean),
            rationale: rationale(for: match, market: market, lean: lean),
            desk: deskName(for: match.sport),
            code: code(for: match, market: market),
            match: match,
            createdAt: match.date.addingTimeInterval(-3600 * Double(5 + offset))
        )
    }

    private static func market(for match: Match, index: Int) -> PickMarket {
        let options = PickMarket.deskMarkets(for: match.sport)
        return options[index % options.count]
    }

    private static func extraMarket(for match: Match, excluding: PickMarket) -> PickMarket? {
        PickMarket.deskMarkets(for: match.sport).first { $0 != excluding }
    }

    private static func lean(for match: Match, market: PickMarket, index: Int) -> PickLean {
        let seed = match.homeTeam.unicodeScalars.reduce(0) { $0 &+ Int($1.value) } &+ index
        switch market {
        case .oneXTwo:
            if match.sport.allowsDraw && seed % 6 == 0 { return .draw }
            return seed % 2 == 0 ? .home : .away
        case .homeOrDraw, .overTwoFive, .bothScore:
            return .home
        case .awayOrDraw:
            return .away
        case .underTwoFive:
            return seed % 3 == 0 ? .away : .home
        }
    }

    private static func code(for match: Match, market: PickMarket) -> String {
        let home = String(match.homeTeam.uppercased().filter(\.isLetter).prefix(3))
        let away = String(match.awayTeam.uppercased().filter(\.isLetter).prefix(2))
        let tag = market.codeTag
        return "MJ-\(tag)-\(home)\(away)"
    }

    private static func deskName(for sport: Sport) -> String {
        switch sport {
        case .soccer: return "European coverage"
        case .basketball: return "Hoops coverage"
        case .tennis: return "Tour coverage"
        case .baseball: return "Diamond coverage"
        case .hockey: return "Ice coverage"
        case .esports: return "Maps coverage"
        }
    }

    private static func headline(for match: Match, market: PickMarket, lean: PickLean) -> String {
        switch market {
        case .oneXTwo:
            switch lean {
            case .home: return "Match result · \(match.homeTeam)"
            case .away: return "Match result · \(match.awayTeam)"
            case .draw: return "Match result · draw"
            }
        case .homeOrDraw:
            return "Home or draw on \(match.homeTeam)"
        case .awayOrDraw:
            return "Away or draw on \(match.awayTeam)"
        case .bothScore:
            return lean == .away ? "Both teams to stay quiet" : "Both teams to score"
        case .overTwoFive:
            return "Over 2.5 goals in \(match.league.isEmpty ? match.sport.rawValue : match.league)"
        case .underTwoFive:
            return "Under 2.5 goals — tight game script"
        }
    }

    private static func rationale(for match: Match, market: PickMarket, lean: PickLean) -> String {
        let form = MatchPreviewFactory.formLine(for: match)
        switch market {
        case .oneXTwo:
            let side = lean == .draw ? "a draw" : (lean == .home ? match.homeTeam : match.awayTeam)
            return "\(form) Form and chance creation point toward \(side) on the match result grid."
        case .homeOrDraw:
            return "\(form) Home or draw covers a home win or a stalemate — useful when \(match.homeTeam) controls territory but the finish is messy."
        case .awayOrDraw:
            return "\(form) Away or draw fits when \(match.awayTeam) travels well and the home side has been leaking late."
        case .bothScore:
            return "\(form) Both attacks have been getting shots away. Both to score looks likely unless the match script turns ultra-low."
        case .overTwoFive:
            return "\(form) Combined recent scoring is high enough that over 2.5 goals is the cleaner read."
        case .underTwoFive:
            return "\(form) Two compact blocks. Under 2.5 goals is the read if the first goal is slow."
        }
    }
}

enum MatchPreviewFactory {
    struct FormRow: Hashable {
        var lastFive: [String]
        var scored: Int
        var conceded: Int
    }

    struct Preview: Hashable {
        var home: FormRow
        var away: FormRow
        var homeWins: Int
        var awayWins: Int
        var draws: Int
        var note: String
    }

    static func preview(for match: Match) -> Preview {
        let home = form(for: match.homeTeam, offset: 1)
        let away = form(for: match.awayTeam, offset: 4)
        let split = h2h(home: match.homeTeam, away: match.awayTeam)
        let note: String
        if split.home > split.away {
            note = "Recent H2H tilts toward \(match.homeTeam)."
        } else if split.away > split.home {
            note = "Recent H2H tilts toward \(match.awayTeam)."
        } else {
            note = "Recent H2H is even. Trust the current form, not the history."
        }
        return Preview(home: home, away: away, homeWins: split.home, awayWins: split.away, draws: split.draw, note: note)
    }

    static func formLine(for match: Match) -> String {
        let home = form(for: match.homeTeam, offset: 1).lastFive.joined()
        let away = form(for: match.awayTeam, offset: 4).lastFive.joined()
        return "\(match.homeTeam) last five \(home). \(match.awayTeam) last five \(away)."
    }

    private static func form(for team: String, offset: Int) -> FormRow {
        let seed = team.unicodeScalars.reduce(0) { $0 &+ Int($1.value) } &+ offset
        let letters = ["W", "D", "L"]
        var last: [String] = []
        var scored = 0
        var conceded = 0
        for i in 0..<5 {
            let token = letters[(seed + i * 3) % letters.count]
            last.append(token)
            switch token {
            case "W":
                scored += 1 + (seed + i) % 3
                conceded += (seed + i) % 2
            case "D":
                scored += (seed + i) % 2
                conceded += (seed + i) % 2
            default:
                scored += (seed + i) % 2
                conceded += 1 + (seed + i) % 3
            }
        }
        return FormRow(lastFive: last, scored: scored, conceded: conceded)
    }

    private static func h2h(home: String, away: String) -> (home: Int, away: Int, draw: Int) {
        let seed = home.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
            &+ away.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return (home: seed % 4, away: (seed / 3) % 4, draw: (seed / 5) % 3)
    }
}

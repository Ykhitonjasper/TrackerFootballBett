import Foundation
import SwiftData

@Model
final class MatchPick {
    @Attribute(.unique) var id: UUID
    var leanRaw: String
    var marketRaw: String
    var confidence: Int
    var headline: String
    var rationale: String
    var desk: String
    var code: String
    var createdAt: Date
    var resultRaw: String

    var match: Match?

    var lean: PickLean {
        get { PickLean(rawValue: leanRaw) ?? .home }
        set { leanRaw = newValue.rawValue }
    }

    var market: PickMarket {
        get {
            if let parsed = PickMarket(rawValue: marketRaw) { return parsed }
            switch marketRaw {
            case "1X2": return .oneXTwo
            case "1X": return .homeOrDraw
            case "X2": return .awayOrDraw
            case "BTTS": return .bothScore
            case "O2.5": return .overTwoFive
            case "U2.5": return .underTwoFive
            default: return .oneXTwo
            }
        }
        set { marketRaw = newValue.rawValue }
    }

    var result: PickResult {
        get { PickResult(rawValue: resultRaw) ?? .open }
        set { resultRaw = newValue.rawValue }
    }

    var selectionLabel: String {
        guard let match else { return "\(market.rawValue) \(lean.shortLabel)" }
        switch market {
        case .oneXTwo:
            switch lean {
            case .home: return "1 · \(match.homeTeam)"
            case .draw: return "X · Draw"
            case .away: return "2 · \(match.awayTeam)"
            }
        case .homeOrDraw:
            return "Home or Draw · \(match.homeTeam)"
        case .awayOrDraw:
            return "Away or Draw · \(match.awayTeam)"
        case .bothScore:
            return lean == .away ? "Both to Score · No" : "Both to Score · Yes"
        case .overTwoFive:
            return "Over 2.5"
        case .underTwoFive:
            return "Under 2.5"
        }
    }

    var shareText: String {
        let fixture = match?.displayName ?? "Fixture"
        let when = match.map { DateFormatters.dayKickoff.string(from: $0.date) } ?? ""
        return "\(code) · \(fixture) · \(selectionLabel) · confidence \(confidence)/5 · \(when)"
    }

    init(
        id: UUID = UUID(),
        lean: PickLean,
        market: PickMarket = .oneXTwo,
        confidence: Int,
        headline: String,
        rationale: String,
        desk: String,
        code: String,
        match: Match?,
        createdAt: Date = Date(),
        result: PickResult = .open
    ) {
        self.id = id
        self.leanRaw = lean.rawValue
        self.marketRaw = market.rawValue
        self.confidence = min(5, max(1, confidence))
        self.headline = headline
        self.rationale = rationale
        self.desk = desk
        self.code = code
        self.match = match
        self.createdAt = createdAt
        self.resultRaw = result.rawValue
    }
}

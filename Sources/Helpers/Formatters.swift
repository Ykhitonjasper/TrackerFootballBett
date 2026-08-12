import Foundation

enum DateFormatters {
    static let kickoff: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static let dayKickoff: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE HH:mm"
        return formatter
    }()

    static let full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static let relative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    static func matchDayLabel(for date: Date, now: Date = Date()) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return shortDate.string(from: date)
    }
}

enum CurrencyFormatter {
    static let usd: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    static func string(from value: Double) -> String {
        usd.string(from: NSNumber(value: value)) ?? String(format: "$%.2f", value)
    }

    static func compact(from value: Double) -> String {
        if abs(value) >= 1000 {
            return String(format: "$%.1fk", value / 1000)
        }
        return String(format: "$%.0f", value)
    }
}

enum OddsCalculator {
    static func impliedProbability(_ odds: Double) -> Double {
        guard odds > 1 else { return 0 }
        return 1.0 / odds
    }

    static func fromProbability(_ probability: Double) -> Double {
        guard probability > 0 && probability < 1 else { return 1.01 }
        let raw = 1.0 / probability
        return (raw * 100).rounded() / 100
    }

    /// Approximate double-chance style combine of two mutually exclusive outcomes.
    static func combine(_ first: Double, _ second: Double) -> Double {
        let p = impliedProbability(first) + impliedProbability(second)
        let margin = 1.05
        return fromProbability(min(0.95, p * margin))
    }

    static func potentialReturn(stake: Double, odds: Double) -> Double {
        stake * odds
    }

    static func profit(stake: Double, odds: Double) -> Double {
        stake * (odds - 1)
    }

    static func cashOutOffer(stake: Double, odds: Double, match: Match) -> Double {
        let base = stake * 0.85
        let liveBoost: Double
        switch match.status {
        case .live:
            liveBoost = Double(match.minute) / 200.0
        case .upcoming:
            liveBoost = 0.05
        default:
            liveBoost = 0
        }
        return max(stake * 0.4, min(stake * odds * 0.92, base + stake * liveBoost))
    }

    static func applyMargin(to fairOdds: Double, margin: Double = 0.06) -> Double {
        let fairProb = impliedProbability(fairOdds)
        return fromProbability(min(0.95, fairProb * (1 + margin)))
    }
}

enum ScoreFormatter {
    static func label(home: Int, away: Int) -> String {
        "\(home) – \(away)"
    }

    static func resultText(home: Int, away: Int) -> String {
        if home > away { return "Home win" }
        if away > home { return "Away win" }
        return "Draw"
    }
}

enum Validation {
    static func stake(from text: String) -> Double? {
        let cleaned = text
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(cleaned), value > 0, value.isFinite else { return nil }
        return (value * 100).rounded() / 100
    }

    static func username(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 3 && trimmed.count <= 20
    }
}

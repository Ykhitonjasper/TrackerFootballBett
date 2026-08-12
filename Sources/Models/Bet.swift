import Foundation
import SwiftData

@Model
final class Bet {
    @Attribute(.unique) var id: UUID
    var amount: Double
    var odds: Double
    var datePlaced: Date
    var betTypeRaw: String
    var outcomeRaw: String
    var settledAt: Date?
    var cashOutValue: Double?
    var note: String

    var match: Match?

    var type: BetType {
        get { BetType(rawValue: betTypeRaw) ?? .homeWin }
        set { betTypeRaw = newValue.rawValue }
    }

    var outcome: BetOutcome {
        get { BetOutcome(rawValue: outcomeRaw) ?? .pending }
        set { outcomeRaw = newValue.rawValue }
    }

    var potentialPayout: Double {
        amount * odds
    }

    var profitIfWin: Double {
        potentialPayout - amount
    }

    var realizedProfit: Double {
        switch outcome {
        case .won:
            return profitIfWin
        case .lost:
            return -amount
        case .cashedOut:
            return (cashOutValue ?? amount) - amount
        case .void:
            return 0
        case .pending:
            return 0
        }
    }

    var matchTitle: String {
        match?.displayName ?? "Unknown match"
    }

    init(
        id: UUID = UUID(),
        amount: Double,
        odds: Double,
        type: BetType,
        match: Match?,
        outcome: BetOutcome = .pending,
        datePlaced: Date = Date(),
        settledAt: Date? = nil,
        cashOutValue: Double? = nil,
        note: String = ""
    ) {
        self.id = id
        self.amount = amount
        self.odds = odds
        self.betTypeRaw = type.rawValue
        self.match = match
        self.outcomeRaw = outcome.rawValue
        self.datePlaced = datePlaced
        self.settledAt = settledAt
        self.cashOutValue = cashOutValue
        self.note = note
    }
}

import Foundation
import SwiftData

enum MockBetFactory {
    /// Seeds a lived-in ticket history so My Bets / Profile / Activity are never empty.
    static func seedDemoBets(into context: ModelContext, profile: UserProfile) {
        let existing = (try? context.fetchCount(FetchDescriptor<Bet>())) ?? 0
        guard existing == 0 else { return }

        let matches = (try? context.fetch(FetchDescriptor<Match>(sortBy: [SortDescriptor(\.popularity, order: .reverse)]))) ?? []
        guard !matches.isEmpty else { return }

        let live = matches.filter { $0.status == .live }
        let upcoming = matches.filter { $0.status == .upcoming }
        let finished = matches.filter { $0.status == .finished }

        var tickets: [(Match, BetType, Double, BetOutcome, TimeInterval)] = []

        for (index, match) in finished.prefix(6).enumerated() {
            let type: BetType = [.homeWin, .awayWin, .draw, .over, .under][index % 5]
            let outcome: BetOutcome = index % 3 == 0 ? .lost : .won
            tickets.append((match, type, [15, 25, 40, 50, 75, 100][index % 6], outcome, -Double((index + 1) * 18_000)))
        }

        for (index, match) in live.prefix(4).enumerated() {
            tickets.append((match, index % 2 == 0 ? .homeWin : .awayWin, [20, 35, 50, 60][index % 4], .pending, -Double((index + 1) * 2_400)))
        }

        for (index, match) in upcoming.prefix(3).enumerated() {
            tickets.append((match, .homeWin, [10, 25, 40][index % 3], .pending, -Double((index + 1) * 900)))
        }

        // One cashed-out sample if possible
        if let liveMatch = live.first {
            tickets.append((liveMatch, .draw, 30, .cashedOut, -3_600))
        }

        var totalWon = 0.0
        var totalLost = 0.0
        var balanceDelta = 0.0

        for ticket in tickets {
            let (match, type, stake, outcome, offset) = ticket
            let odds = match.odds(for: type)
            let placed = Date().addingTimeInterval(offset)
            var settledAt: Date? = nil
            var cashOut: Double? = nil

            switch outcome {
            case .won:
                settledAt = placed.addingTimeInterval(3_600)
                totalWon += stake * (odds - 1)
                balanceDelta += stake * (odds - 1)
            case .lost:
                settledAt = placed.addingTimeInterval(3_600)
                totalLost += stake
                balanceDelta -= stake
            case .pending:
                balanceDelta -= stake
            case .cashedOut:
                cashOut = OddsCalculator.cashOutOffer(stake: stake, odds: odds, match: match)
                settledAt = placed.addingTimeInterval(1_200)
                let profit = (cashOut ?? stake) - stake
                if profit >= 0 { totalWon += profit } else { totalLost += -profit }
                balanceDelta += (cashOut ?? stake) - stake
            case .void:
                break
            }

            // Pending already deducted; won/lost/cashout adjust relative to deduction
            if outcome == .won {
                // stake was conceptually risked earlier — credit full payout net of stake already counted in balanceDelta via profit only
            }

            let bet = Bet(
                amount: stake,
                odds: odds,
                type: type,
                match: match,
                outcome: outcome,
                datePlaced: placed,
                settledAt: settledAt,
                cashOutValue: cashOut,
                note: outcome == .pending ? "Demo open ticket" : ""
            )
            context.insert(bet)
        }

        // Rebuild a sensible demo bankroll around the starter amount
        profile.balance = max(420, min(1_850, 1_000 + balanceDelta))
        profile.totalWon = max(0, totalWon)
        profile.totalLost = max(0, totalLost)
        profile.totalBetsPlaced = tickets.count
        profile.level = max(2, min(6, 1 + tickets.count / 3))
        profile.experience = 35 + tickets.count * 8
        profile.addExperience(0)

        // Watch a handful of featured / live fixtures
        let watchIds = Set((live + matches.filter(\.isFeatured)).prefix(5).map(\.id))
        WatchlistStore.save(watchIds)

        try? context.save()
    }
}

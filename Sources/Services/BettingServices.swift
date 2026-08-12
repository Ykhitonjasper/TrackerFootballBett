import Foundation
import SwiftData

@MainActor
final class BettingService {
    private let users = UserRepository()

    struct PlacementResult {
        let bet: Bet
        let remainingBalance: Double
    }

    func placeBet(
        match: Match,
        type: BetType,
        stake: Double,
        context: ModelContext,
        note: String = ""
    ) throws -> PlacementResult {
        guard match.status.isBettable else { throw BettingError.matchClosed }
        guard stake > 0 else { throw BettingError.invalidStake }

        let profile = try users.fetchProfile(context: context)
        guard profile.balance >= stake else { throw BettingError.insufficientFunds }

        let odds = match.odds(for: type)
        profile.balance -= stake
        profile.totalBetsPlaced += 1
        profile.addExperience(5)

        let bet = Bet(
            amount: stake,
            odds: odds,
            type: type,
            match: match,
            outcome: .pending,
            note: note
        )
        context.insert(bet)

        do {
            try context.save()
        } catch {
            throw BettingError.saveFailed
        }

        NotificationCenter.default.post(name: .trackerBetBetPlaced, object: bet.id)
        return PlacementResult(bet: bet, remainingBalance: profile.balance)
    }

    func cashOut(bet: Bet, context: ModelContext) throws {
        guard bet.outcome == .pending, let match = bet.match else {
            throw BettingError.matchClosed
        }

        let offer = OddsCalculator.cashOutOffer(stake: bet.amount, odds: bet.odds, match: match)
        let profile = try users.fetchProfile(context: context)

        bet.outcome = .cashedOut
        bet.cashOutValue = offer
        bet.settledAt = Date()
        profile.balance += offer
        profile.totalWon += max(0, offer - bet.amount)
        if offer < bet.amount {
            profile.totalLost += bet.amount - offer
        }
        profile.addExperience(3)

        try context.save()
        NotificationCenter.default.post(name: .trackerBetSettled, object: bet.id)
    }
}

@MainActor
final class SettlementService {
    private let users = UserRepository()

    func settleFinishedMatches(context: ModelContext) {
        do {
            let finishedRaw = MatchStatus.finished.rawValue
            let pendingRaw = BetOutcome.pending.rawValue

            let matchDescriptor = FetchDescriptor<Match>(
                predicate: #Predicate<Match> { $0.statusRaw == finishedRaw }
            )
            let finished = try context.fetch(matchDescriptor)

            let betDescriptor = FetchDescriptor<Bet>(
                predicate: #Predicate<Bet> { $0.outcomeRaw == pendingRaw }
            )
            let pending = try context.fetch(betDescriptor)
            guard !pending.isEmpty else { return }

            let profile = try users.fetchProfile(context: context)
            var settledCount = 0

            for bet in pending {
                guard let match = bet.match, finished.contains(where: { $0.id == match.id }) else { continue }
                let won = evaluate(bet: bet, match: match)
                bet.outcome = won ? .won : .lost
                bet.settledAt = Date()
                settledCount += 1

                if won {
                    let payout = bet.potentialPayout
                    profile.balance += payout
                    profile.totalWon += bet.profitIfWin
                    profile.addExperience(20)
                } else {
                    profile.totalLost += bet.amount
                    profile.addExperience(2)
                }
            }

            if settledCount > 0 {
                try context.save()
                NotificationCenter.default.post(name: .trackerBetSettled, object: settledCount)
            }
        } catch {
            print("Settlement failed: \(error)")
        }
    }

    func evaluate(bet: Bet, match: Match) -> Bool {
        let homeWon = match.homeScore > match.awayScore
        let awayWon = match.awayScore > match.homeScore
        let draw = match.homeScore == match.awayScore
        let total = match.totalGoals
        let btts = match.homeScore > 0 && match.awayScore > 0

        switch bet.type {
        case .homeWin: return homeWon
        case .awayWin: return awayWon
        case .draw: return draw
        case .over: return total > 2
        case .under: return total < 3
        case .bothTeamsScore: return btts
        case .homeOrDraw: return homeWon || draw
        case .awayOrDraw: return awayWon || draw
        }
    }
}

@MainActor
final class LiveMatchSimulator {
    static let shared = LiveMatchSimulator()

    private var timer: Timer?
    private weak var context: ModelContext?
    private let settlement = SettlementService()

    func start(context: ModelContext) {
        self.context = context
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 12, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        context = nil
    }

    private func tick() {
        guard let context else { return }
        do {
            let matches = try context.fetch(FetchDescriptor<Match>())
            for match in matches {
                switch match.status {
                case .upcoming:
                    if match.date <= Date() {
                        match.status = .live
                        match.minute = 1
                    }
                case .live:
                    advanceLive(match)
                case .finished, .postponed:
                    break
                }
            }
            try context.save()
            settlement.settleFinishedMatches(context: context)
        } catch {
            print("Live simulation tick failed: \(error)")
        }
    }

    private func advanceLive(_ match: Match) {
        match.minute = min(95, match.minute + Int.random(in: 2...5))

        let scoringChance: Double
        switch match.sport {
        case .soccer, .hockey: scoringChance = 0.28
        case .basketball: scoringChance = 0.75
        case .tennis: scoringChance = 0.45
        case .baseball: scoringChance = 0.35
        case .esports: scoringChance = 0.40
        }

        if Double.random(in: 0...1) < scoringChance {
            if Bool.random() {
                match.homeScore += scoreIncrement(for: match.sport)
            } else {
                match.awayScore += scoreIncrement(for: match.sport)
            }
            nudgeOdds(match)
        }

        if match.minute >= 90 || (match.sport != .soccer && match.sport != .hockey && match.minute >= 48) {
            if Double.random(in: 0...1) < 0.35 {
                match.status = .finished
                match.minute = match.sport == .soccer || match.sport == .hockey ? 90 : match.minute
            }
        }
    }

    private func scoreIncrement(for sport: Sport) -> Int {
        switch sport {
        case .basketball: return Int.random(in: 1...3)
        case .tennis: return 1
        default: return 1
        }
    }

    private func nudgeOdds(_ match: Match) {
        let delta = Double.random(in: -0.08...0.08)
        match.homeOdds = max(1.15, (match.homeOdds + delta * (match.homeScore >= match.awayScore ? -1 : 1) * 100).rounded() / 100)
        match.awayOdds = max(1.15, (match.awayOdds - delta * (match.homeScore >= match.awayScore ? -1 : 1) * 100).rounded() / 100)
        if let draw = match.drawOdds {
            match.drawOdds = max(2.4, ((draw + Double.random(in: -0.05...0.05)) * 100).rounded() / 100)
        }
    }
}

@MainActor
final class LeaderboardService {
    func build(context: ModelContext) throws -> [LeaderboardEntry] {
        let profile = try UserRepository().fetchProfile(context: context)
        let bets = try BetRepository().fetchAll(context: context)
        let settled = bets.filter { $0.outcome.isSettled && $0.outcome != .void }
        let wins = settled.filter { $0.outcome == .won }.count
        let winRate = settled.isEmpty ? 0 : Double(wins) / Double(settled.count)

        let userEntry = LeaderboardEntry(
            username: profile.username,
            points: Int(profile.netProfit.rounded()),
            rank: 0,
            avatarColor: "#1475E1",
            winRate: winRate,
            totalBets: profile.totalBetsPlaced,
            isCurrentUser: true
        )

        var entries = MockLeaderboardFactory.generateMockEntries()
        entries.append(userEntry)
        entries.sort { $0.points > $1.points }

        return entries.enumerated().map { index, entry in
            LeaderboardEntry(
                id: entry.id,
                username: entry.username,
                points: entry.points,
                rank: index + 1,
                avatarColor: entry.avatarColor,
                winRate: entry.winRate,
                totalBets: entry.totalBets,
                isCurrentUser: entry.isCurrentUser
            )
        }
    }
}

@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var items: [AppNotification] = MockNotificationFactory.seed()

    var unreadCount: Int {
        items.filter { !$0.isRead }.count
    }

    func markAllRead() {
        items = items.map {
            var copy = $0
            copy.isRead = true
            return copy
        }
    }

    func markRead(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isRead = true
    }

    func push(_ notification: AppNotification) {
        items.insert(notification, at: 0)
    }
}

import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class MatchFeedViewModel {
    var state: ViewState<[Match]> = .idle
    var featured: [Match] = []
    var searchQuery: String = ""
    var selectedSport: Sport? = nil
    var statusFilter: FeedStatusFilter = .all
    var sortOption: SortOption = .kickoff

    private let repository = MatchRepository()
    private let settlement = SettlementService()

    var sportFilters: [Sport?] { [nil] + Sport.allCases.map { Optional($0) } }

    func load(context: ModelContext) {
        state = .loading
        do {
            SeedService.shared.seedIfNeeded(context: context)
            settlement.settleFinishedMatches(context: context)
            let matches = try repository.fetch(
                context: context,
                sport: selectedSport,
                status: statusFilter.matchStatus,
                query: AliasIndex.expandQuery(searchQuery),
                sort: sortOption
            )
            featured = try repository.featured(context: context)
            state = matches.isEmpty ? .empty : .loaded(matches)
            LiveMatchSimulator.shared.start(context: context)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func refresh(context: ModelContext) {
        load(context: context)
    }

    func applySport(_ sport: Sport?, context: ModelContext) {
        selectedSport = sport
        load(context: context)
    }

    func applyStatus(_ filter: FeedStatusFilter, context: ModelContext) {
        statusFilter = filter
        load(context: context)
    }

    func applySort(_ sort: SortOption, context: ModelContext) {
        sortOption = sort
        load(context: context)
    }
}

@Observable
@MainActor
final class MatchDetailViewModel {
    var match: Match
    var timeline: [TimelineEvent] = []
    var stats: MatchStats = .empty
    var selectedBetType: BetType?
    var markets: [BetType] = []

    init(match: Match) {
        self.match = match
        self.markets = BetType.marketTypes(for: match.sport)
        reloadDerived()
    }

    func reloadDerived() {
        timeline = MockTimelineFactory.events(for: match)
        stats = MockStatsFactory.stats(for: match)
        markets = BetType.marketTypes(for: match.sport)
    }

    func select(_ type: BetType) {
        selectedBetType = type
    }

    func odds(for type: BetType) -> Double {
        match.odds(for: type)
    }
}

@Observable
@MainActor
final class PlaceBetViewModel {
    var stakeText: String = "25"
    var note: String = ""
    var errorMessage: String?
    var successMessage: String?
    var isPlacing = false
    var balance: Double = 0

    private let betting = BettingService()
    private let users = UserRepository()

    var stakeValue: Double? {
        Validation.stake(from: stakeText)
    }

    var potentialReturn: Double {
        guard let stake = stakeValue else { return 0 }
        return stake
    }

    func loadBalance(context: ModelContext) {
        balance = (try? users.fetchProfile(context: context).balance) ?? 0
    }

    func setPreset(_ value: Double) {
        stakeText = value == floor(value) ? String(Int(value)) : String(format: "%.2f", value)
        errorMessage = nil
    }

    func place(match: Match, type: BetType, context: ModelContext) {
        errorMessage = nil
        successMessage = nil

        guard let stake = stakeValue else {
            errorMessage = BettingError.invalidStake.message
            return
        }

        isPlacing = true
        do {
            let result = try betting.placeBet(
                match: match,
                type: type,
                stake: stake,
                context: context,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            balance = result.remainingBalance
            successMessage = "Bet placed · potential \(CurrencyFormatter.string(from: result.bet.potentialPayout))"
            stakeText = ""
            note = ""
        } catch let error as BettingError {
            errorMessage = error.message
        } catch {
            errorMessage = error.localizedDescription
        }
        isPlacing = false
    }
}

@Observable
@MainActor
final class MyBetsViewModel {
    enum BetFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case active = "Active"
        case won = "Won"
        case lost = "Lost"
        case cashedOut = "Cash Out"

        var id: String { rawValue }
    }

    var state: ViewState<[Bet]> = .idle
    var selectedFilter: BetFilter = .all
    var totalStake: Double = 0
    var totalProfitLoss: Double = 0
    var openExposure: Double = 0

    private let repository = BetRepository()
    private let settlement = SettlementService()

    func load(context: ModelContext) {
        state = .loading
        do {
            settlement.settleFinishedMatches(context: context)
            let all = try repository.fetchAll(context: context)
            let filtered: [Bet]
            switch selectedFilter {
            case .all: filtered = all
            case .active: filtered = all.filter { $0.outcome == .pending }
            case .won: filtered = all.filter { $0.outcome == .won }
            case .lost: filtered = all.filter { $0.outcome == .lost }
            case .cashedOut: filtered = all.filter { $0.outcome == .cashedOut }
            }

            totalStake = all.reduce(0) { $0 + $1.amount }
            totalProfitLoss = all.reduce(0) { $0 + $1.realizedProfit }
            openExposure = all.filter { $0.outcome == .pending }.reduce(0) { $0 + $1.amount }

            state = filtered.isEmpty ? .empty : .loaded(filtered)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}

@Observable
@MainActor
final class ProfileViewModel {
    struct DashboardData {
        var snapshot: PerformanceAnalytics.Snapshot
        var series: [(date: Date, profit: Double)]
    }

    var state: ViewState<UserProfile> = .idle
    var totalBetsPlaced: Int = 0
    var winRate: Double = 0
    var avgOdds: Double = 0
    var bestWin: Double = 0
    var currentStreak: Int = 0
    var dashboard: DashboardData?
    var recentTickets: [Bet] = []

    private let users = UserRepository()
    private let bets = BetRepository()

    func load(context: ModelContext) {
        state = .loading
        do {
            let profile = try users.fetchProfile(context: context)
            let allBets = try bets.fetchAll(context: context)
            totalBetsPlaced = allBets.count
            recentTickets = Array(allBets.prefix(6))

            let settled = allBets.filter { $0.outcome == .won || $0.outcome == .lost }
            let won = settled.filter { $0.outcome == .won }
            winRate = settled.isEmpty ? 0 : Double(won.count) / Double(settled.count) * 100
            avgOdds = allBets.isEmpty ? 0 : allBets.reduce(0) { $0 + $1.odds } / Double(allBets.count)
            bestWin = won.map(\.profitIfWin).max() ?? 0
            currentStreak = computeStreak(allBets)
            dashboard = DashboardData(
                snapshot: PerformanceAnalytics.snapshot(from: allBets),
                series: PerformanceAnalytics.profitSeries(from: allBets)
            )

            state = .loaded(profile)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func resetDemo(context: ModelContext) {
        SeedService.shared.resetDemoData(context: context)
        load(context: context)
    }

    func updatePreferences(notifications: Bool, sound: Bool, context: ModelContext) {
        guard case .loaded(let profile) = state else { return }
        profile.notificationsEnabled = notifications
        profile.soundEnabled = sound
        try? context.save()
    }

    private func computeStreak(_ bets: [Bet]) -> Int {
        var streak = 0
        for bet in bets where bet.outcome == .won || bet.outcome == .lost {
            if bet.outcome == .won {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
}

@Observable
@MainActor
final class NotificationsViewModel {
    private let service = NotificationService.shared

    var items: [AppNotification] { service.items }
    var unreadCount: Int { service.unreadCount }

    func markAllRead() { service.markAllRead() }
    func markRead(_ id: UUID) { service.markRead(id) }
}

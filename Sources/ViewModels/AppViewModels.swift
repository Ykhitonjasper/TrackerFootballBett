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

    var sportFilters: [Sport?] { [nil] + Sport.allCases.map { Optional($0) } }

    func load(context: ModelContext) {
        state = .loading
        do {
            SeedService.shared.seedIfNeeded(context: context)
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

    init(match: Match) {
        self.match = match
        reloadDerived()
    }

    func reloadDerived() {
        timeline = MockTimelineFactory.events(for: match)
        stats = MockStatsFactory.stats(for: match)
    }
}

@Observable
@MainActor
final class ProfileViewModel {
    struct DashboardData {
        var snapshot: FollowAnalytics.Snapshot
        var series: [(date: Date, count: Int)]
    }

    var state: ViewState<UserProfile> = .idle
    var watchCount: Int = 0
    var liveCount: Int = 0
    var upcomingCount: Int = 0
    var finishedCount: Int = 0
    var openPicks: Int = 0
    var hitPicks: Int = 0
    var dashboard: DashboardData?
    var recentWatched: [Match] = []

    private let users = UserRepository()
    private let matches = MatchRepository()

    func load(context: ModelContext) {
        state = .loading
        do {
            let profile = try users.fetchProfile(context: context)
            let all = try matches.fetchAll(context: context)
            let ids = WatchlistStore.load()
            let watched = all.filter { ids.contains($0.id) }.sorted { $0.date < $1.date }

            watchCount = watched.count
            liveCount = all.filter { $0.status == .live }.count
            upcomingCount = all.filter { $0.status == .upcoming }.count
            finishedCount = all.filter { $0.status == .finished }.count
            let picks = all.compactMap(\.primaryPick)
            PickSettler.settleAll(in: context)
            let snap = PickAnalytics.snapshot(from: picks)
            openPicks = snap.openCount
            hitPicks = snap.hitCount
            recentWatched = Array(watched.prefix(6))
            dashboard = DashboardData(
                snapshot: FollowAnalytics.snapshot(all: all, watched: watched),
                series: FollowAnalytics.fixtureSeries(from: all)
            )

            state = .loaded(profile)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func resetLocalData(context: ModelContext) {
        SeedService.shared.resetLocalData(context: context)
        load(context: context)
    }

    func updatePreferences(notifications: Bool, sound: Bool, context: ModelContext) {
        guard case .loaded(let profile) = state else { return }
        profile.notificationsEnabled = notifications
        profile.soundEnabled = sound
        try? context.save()
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

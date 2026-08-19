import Foundation
import SwiftData

@MainActor
final class SeedService {
    static let shared = SeedService()

    private let seededKey = "trackerbet.didSeed.v7"

    func seedIfNeeded(context: ModelContext) {
        let alreadySeeded = UserDefaults.standard.bool(forKey: seededKey)
        let matchCount = (try? context.fetchCount(FetchDescriptor<Match>())) ?? 0

        if !alreadySeeded || matchCount == 0 {
            clearMatches(context: context)
            MockMatchFactory.seedMatches(into: context)
            MockPickFactory.seedPicks(into: context)
            _ = ensureProfile(context: context)
            seedWatchlist(context: context)
            try? context.save()
            UserDefaults.standard.set(true, forKey: seededKey)
        } else {
            _ = ensureProfile(context: context)
        }
    }

    func resetLocalData(context: ModelContext) {
        clearMatches(context: context)
        clearProfiles(context: context)
        MockMatchFactory.seedMatches(into: context)
        MockPickFactory.seedPicks(into: context)
        _ = ensureProfile(context: context, forceDefault: true)
        seedWatchlist(context: context, force: true)
        try? context.save()
        UserDefaults.standard.set(true, forKey: seededKey)
        NotificationCenter.default.post(name: .trackerBetDataReset, object: nil)
    }

    private func seedWatchlist(context: ModelContext, force: Bool = false) {
        if !force && !WatchlistStore.load().isEmpty { return }
        let matches = (try? context.fetch(FetchDescriptor<Match>())) ?? []
        let ids = Set(
            matches
                .filter { $0.isFeatured || $0.status == .live }
                .prefix(8)
                .map(\.id)
        )
        WatchlistStore.save(ids)
    }

    @discardableResult
    private func ensureProfile(context: ModelContext, forceDefault: Bool = false) -> UserProfile {
        let profiles = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
        if forceDefault {
            profiles.forEach { context.delete($0) }
        }
        if forceDefault || profiles.isEmpty {
            let profile = UserProfile(
                displayName: "Fan",
                favoriteSport: .soccer
            )
            context.insert(profile)
            return profile
        }
        return profiles[0]
    }

    private func clearMatches(context: ModelContext) {
        let matches = (try? context.fetch(FetchDescriptor<Match>())) ?? []
        matches.forEach { context.delete($0) }
    }

    private func clearProfiles(context: ModelContext) {
        let profiles = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
        profiles.forEach { context.delete($0) }
    }
}

extension Notification.Name {
    static let trackerBetDataReset = Notification.Name("trackerBetDataReset")
}

@MainActor
final class UserRepository {
    func fetchProfile(context: ModelContext) throws -> UserProfile {
        let descriptor = FetchDescriptor<UserProfile>()
        if let existing = try context.fetch(descriptor).first {
            return existing
        }
        let created = UserProfile()
        context.insert(created)
        try context.save()
        return created
    }
}

@MainActor
final class MatchRepository {
    func fetchAll(context: ModelContext) throws -> [Match] {
        let descriptor = FetchDescriptor<Match>(sortBy: [SortDescriptor(\.date)])
        return try context.fetch(descriptor)
    }

    func fetch(
        context: ModelContext,
        sport: Sport?,
        status: MatchStatus?,
        query: String,
        sort: SortOption
    ) throws -> [Match] {
        var matches = try fetchAll(context: context)

        if let sport {
            matches = matches.filter { $0.sport == sport }
        }
        if let status {
            matches = matches.filter { $0.status == status }
        }
        if !query.isEmpty {
            matches = matches.filter {
                $0.homeTeam.localizedCaseInsensitiveContains(query)
                    || $0.awayTeam.localizedCaseInsensitiveContains(query)
                    || $0.league.localizedCaseInsensitiveContains(query)
            }
        }

        switch sort {
        case .kickoff:
            matches.sort { $0.date < $1.date }
        case .popularity:
            matches.sort { $0.popularity > $1.popularity }
        case .league:
            matches.sort { $0.league < $1.league }
        }

        return matches
    }

    func featured(context: ModelContext) throws -> [Match] {
        try fetchAll(context: context)
            .filter { $0.isFeatured && $0.status.isActive }
            .sorted { $0.popularity > $1.popularity }
    }
}

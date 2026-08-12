import Foundation
import SwiftData

@MainActor
final class SeedService {
    static let shared = SeedService()

    private let seededKey = "trackerbet.didSeed.v3"

    func seedIfNeeded(context: ModelContext) {
        let alreadySeeded = UserDefaults.standard.bool(forKey: seededKey)
        let matchCount = (try? context.fetchCount(FetchDescriptor<Match>())) ?? 0

        if !alreadySeeded || matchCount == 0 {
            clearBets(context: context)
            clearMatches(context: context)
            MockMatchFactory.seedMatches(into: context)
            let profile = ensureProfile(context: context)
            MockBetFactory.seedDemoBets(into: context, profile: profile)
            try? context.save()
            UserDefaults.standard.set(true, forKey: seededKey)
        } else {
            let profile = ensureProfile(context: context)
            MockBetFactory.seedDemoBets(into: context, profile: profile)
        }
    }

    func resetDemoData(context: ModelContext) {
        clearBets(context: context)
        clearMatches(context: context)
        clearProfiles(context: context)
        MockMatchFactory.seedMatches(into: context)
        let profile = ensureProfile(context: context, forceDefault: true)
        MockBetFactory.seedDemoBets(into: context, profile: profile)
        try? context.save()
        UserDefaults.standard.set(true, forKey: seededKey)
        NotificationCenter.default.post(name: .trackerBetDataReset, object: nil)
    }

    @discardableResult
    private func ensureProfile(context: ModelContext, forceDefault: Bool = false) -> UserProfile {
        let profiles = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
        if forceDefault {
            profiles.forEach { context.delete($0) }
        }
        if forceDefault || profiles.isEmpty {
            let profile = UserProfile(
                balance: 1000,
                username: "PlayerOne",
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

    private func clearBets(context: ModelContext) {
        let bets = (try? context.fetch(FetchDescriptor<Bet>())) ?? []
        bets.forEach { context.delete($0) }
    }

    private func clearProfiles(context: ModelContext) {
        let profiles = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
        profiles.forEach { context.delete($0) }
    }
}

extension Notification.Name {
    static let trackerBetDataReset = Notification.Name("trackerBetDataReset")
    static let trackerBetBetPlaced = Notification.Name("trackerBetBetPlaced")
    static let trackerBetSettled = Notification.Name("trackerBetSettled")
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
        case .oddsLow:
            matches.sort { $0.homeOdds < $1.homeOdds }
        case .oddsHigh:
            matches.sort { $0.homeOdds > $1.homeOdds }
        case .popularity:
            matches.sort { $0.popularity > $1.popularity }
        }

        return matches
    }

    func featured(context: ModelContext) throws -> [Match] {
        try fetchAll(context: context)
            .filter { $0.isFeatured && $0.status.isBettable }
            .sorted { $0.popularity > $1.popularity }
    }
}

@MainActor
final class BetRepository {
    func fetchAll(context: ModelContext) throws -> [Bet] {
        let descriptor = FetchDescriptor<Bet>(sortBy: [SortDescriptor(\.datePlaced, order: .reverse)])
        return try context.fetch(descriptor)
    }

    func fetchPending(context: ModelContext) throws -> [Bet] {
        try fetchAll(context: context).filter { $0.outcome == .pending }
    }
}

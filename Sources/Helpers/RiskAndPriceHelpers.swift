import Foundation

enum SearchSuggestions {
    static func suggest(from query: String) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return ["Arsenal", "Lakers", "Djokovic", "T1", "Maple Leafs", "Yankees"]
        }
        var results = TeamCatalog.searchTeams(query: trimmed, limit: 8)
        let leagues = LeagueCatalog.all
            .map(\.name)
            .filter { $0.localizedCaseInsensitiveContains(trimmed) }
        results.append(contentsOf: leagues)
        return Array(Set(results)).sorted().prefix(10).map { $0 }
    }
}

enum AppCopy {
    static let disclaimer = "Match Journal is a local match journal with live scores, form, and a personal watchlist."
    static let resetWarning = "Resetting reloads the fixture slate, predictions, and local profile."
    static let liveHint = "Live scores update on a short timer. Finished games lock at full time."
    static let watchlistHint = "Star fixtures to revisit them quickly from Profile."
}

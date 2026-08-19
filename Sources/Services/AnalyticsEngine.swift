import Foundation

/// Fixture mix and watchlist helpers for the companion feed.
enum FollowAnalytics {
    struct Snapshot: Hashable {
        var fixtureCount: Int
        var liveCount: Int
        var upcomingCount: Int
        var finishedCount: Int
        var watchedCount: Int
        var sportsCovered: Int
        var topSport: Sport?
    }

    static func snapshot(all: [Match], watched: [Match]) -> Snapshot {
        let sports = Set(all.map(\.sport))
        let watchedSports = Dictionary(grouping: watched, by: \.sport)
        let top = watchedSports.max(by: { $0.value.count < $1.value.count })?.key
            ?? Dictionary(grouping: all, by: \.sport).max(by: { $0.value.count < $1.value.count })?.key

        return Snapshot(
            fixtureCount: all.count,
            liveCount: all.filter { $0.status == .live }.count,
            upcomingCount: all.filter { $0.status == .upcoming }.count,
            finishedCount: all.filter { $0.status == .finished }.count,
            watchedCount: watched.count,
            sportsCovered: sports.count,
            topSport: top
        )
    }

    static func fixtureSeries(from matches: [Match], days: Int = 7) -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var series: [(Date, Int)] = []
        for offset in (0..<days).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let count = matches.filter { calendar.isDate($0.date, inSameDayAs: day) }.count
            series.append((day, count))
        }
        return series
    }

    static func sportBreakdown(from matches: [Match]) -> [(sport: Sport, count: Int, live: Int)] {
        Dictionary(grouping: matches, by: \.sport)
            .map { sport, items in
                (sport: sport, count: items.count, live: items.filter { $0.status == .live }.count)
            }
            .sorted { $0.count > $1.count }
    }
}

enum MatchInsightEngine {
    struct Insight: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let detail: String
        let sentiment: Sentiment

        enum Sentiment: String { case positive, neutral, caution }
    }

    static func insights(for match: Match) -> [Insight] {
        var items: [Insight] = []

        if match.status == .upcoming {
            items.append(Insight(title: "Kickoff ahead", detail: "\(match.homeTeam) hosts \(match.awayTeam) at \(match.clockLabel).", sentiment: .neutral))
        } else if match.homeScore > match.awayScore {
            items.append(Insight(title: "Home ahead", detail: "\(match.homeTeam) leads \(match.scoreLine).", sentiment: .positive))
        } else if match.awayScore > match.homeScore {
            items.append(Insight(title: "Away ahead", detail: "\(match.awayTeam) leads \(match.scoreLine).", sentiment: .positive))
        } else {
            items.append(Insight(title: "Level score", detail: "The sides are tied at \(match.scoreLine).", sentiment: .neutral))
        }

        if match.status == .live {
            items.append(Insight(title: "Live clock", detail: "This fixture is in play. Scores and minutes refresh on a short timer.", sentiment: .caution))
            if abs(match.homeScore - match.awayScore) >= 2 {
                items.append(Insight(title: "Score gap", detail: "One side has a clear lead on the current scoreboard.", sentiment: .neutral))
            }
        }

        if match.status == .finished {
            items.append(Insight(title: "Full time", detail: "Final result is locked. Open stats for the full comparison.", sentiment: .neutral))
        }

        if match.isFeatured {
            items.append(Insight(title: "Featured fixture", detail: "Pinned because this matchup draws extra attention on the slate.", sentiment: .neutral))
        }

        if match.popularity >= 90 {
            items.append(Insight(title: "High interest", detail: "This card is among the most followed fixtures in the feed.", sentiment: .positive))
        }

        return items
    }
}

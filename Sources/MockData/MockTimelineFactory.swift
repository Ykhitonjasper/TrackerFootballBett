import Foundation

enum MockTimelineFactory {
    static func events(for match: Match) -> [TimelineEvent] {
        switch match.sport {
        case .soccer, .hockey:
            return ballSportTimeline(for: match)
        case .basketball:
            return basketballTimeline(for: match)
        case .tennis:
            return tennisTimeline(for: match)
        case .baseball:
            return baseballTimeline(for: match)
        case .esports:
            return esportsTimeline(for: match)
        }
    }

    private static func ballSportTimeline(for match: Match) -> [TimelineEvent] {
        var events: [TimelineEvent] = [
            TimelineEvent(minute: 1, description: "Kick-off", type: .period, isHome: true)
        ]

        let goalMinutes = uniqueMinutes(count: match.totalGoals, lower: 5, upper: max(6, match.minute == 0 ? 85 : match.minute))
        var homeLeft = match.homeScore
        var awayLeft = match.awayScore

        for minute in goalMinutes {
            let homeScores: Bool
            if homeLeft > 0 && awayLeft > 0 {
                homeScores = Bool.random()
            } else {
                homeScores = homeLeft > 0
            }
            if homeScores {
                homeLeft -= 1
                events.append(TimelineEvent(minute: minute, description: "Goal — \(match.homeTeam)", type: .goal, isHome: true))
            } else {
                awayLeft -= 1
                events.append(TimelineEvent(minute: minute, description: "Goal — \(match.awayTeam)", type: .goal, isHome: false))
            }
        }

        for minute in uniqueMinutes(count: Int.random(in: 1...3), lower: 10, upper: 80) {
            let home = Bool.random()
            events.append(TimelineEvent(
                minute: minute,
                description: "Yellow card — \(home ? match.homeTeam : match.awayTeam)",
                type: .yellowCard,
                isHome: home
            ))
        }

        if Bool.random() {
            let minute = Int.random(in: 20...75)
            let home = Bool.random()
            events.append(TimelineEvent(
                minute: minute,
                description: "Substitution — \(home ? match.homeTeam : match.awayTeam)",
                type: .substitution,
                isHome: home
            ))
        }

        if match.status == .finished || match.minute >= 45 {
            events.append(TimelineEvent(minute: 45, description: "Half-time", type: .period, isHome: true))
        }
        if match.status == .finished {
            events.append(TimelineEvent(minute: 90, description: "Full-time", type: .period, isHome: true))
        }

        return events.sorted { $0.minute < $1.minute }
    }

    private static func basketballTimeline(for match: Match) -> [TimelineEvent] {
        var events: [TimelineEvent] = []
        let checkpoints = [6, 12, 18, 24, 30, 36, 42, 48]
        for minute in checkpoints where minute <= max(match.minute, match.status == .finished ? 48 : 0) {
            events.append(TimelineEvent(
                minute: minute,
                description: "Quarter update \(match.scoreLine)",
                type: .generic,
                isHome: true
            ))
        }
        if match.homeScore > 0 {
            events.append(TimelineEvent(minute: max(3, match.minute / 2), description: "Run by \(match.homeTeam)", type: .generic, isHome: true))
        }
        if match.awayScore > 0 {
            events.append(TimelineEvent(minute: max(5, match.minute / 3), description: "Run by \(match.awayTeam)", type: .generic, isHome: false))
        }
        return events.sorted { $0.minute < $1.minute }
    }

    private static func tennisTimeline(for match: Match) -> [TimelineEvent] {
        var events: [TimelineEvent] = [
            TimelineEvent(minute: 1, description: "Match begins", type: .period, isHome: true)
        ]
        if match.homeScore > 0 {
            events.append(TimelineEvent(minute: 20, description: "Set won — \(match.homeTeam)", type: .generic, isHome: true))
        }
        if match.awayScore > 0 {
            events.append(TimelineEvent(minute: 35, description: "Set won — \(match.awayTeam)", type: .generic, isHome: false))
        }
        events.append(TimelineEvent(minute: max(10, match.minute), description: "Current score \(match.scoreLine)", type: .generic, isHome: true))
        return events.sorted { $0.minute < $1.minute }
    }

    private static func baseballTimeline(for match: Match) -> [TimelineEvent] {
        var events: [TimelineEvent] = []
        let innings = max(1, match.minute)
        for inning in 1...min(innings, 9) {
            events.append(TimelineEvent(minute: inning, description: "Inning \(inning) — \(match.scoreLine)", type: .period, isHome: true))
        }
        return events
    }

    private static func esportsTimeline(for match: Match) -> [TimelineEvent] {
        var events: [TimelineEvent] = [
            TimelineEvent(minute: 1, description: "Map start", type: .period, isHome: true)
        ]
        if match.totalGoals > 0 {
            events.append(TimelineEvent(minute: 8, description: "First blood — \(Bool.random() ? match.homeTeam : match.awayTeam)", type: .generic, isHome: true))
        }
        events.append(TimelineEvent(minute: max(12, match.minute / 2), description: "Objective taken", type: .generic, isHome: Bool.random()))
        events.append(TimelineEvent(minute: max(15, match.minute), description: "Score \(match.scoreLine)", type: .generic, isHome: true))
        return events.sorted { $0.minute < $1.minute }
    }

    private static func uniqueMinutes(count: Int, lower: Int, upper: Int) -> [Int] {
        guard count > 0, upper >= lower else { return [] }
        var set = Set<Int>()
        var safety = 0
        while set.count < count && safety < 100 {
            set.insert(Int.random(in: lower...upper))
            safety += 1
        }
        return set.sorted()
    }
}

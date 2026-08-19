import Foundation

enum MockNotificationFactory {
    static func seed() -> [AppNotification] {
        [
            AppNotification(
                title: "Welcome",
                body: "Today’s prediction sheet is ready. Open Predictions for match result, both to score, and goal totals.",
                date: Date().addingTimeInterval(-900),
                kind: .system,
                isRead: false
            ),
            AppNotification(
                title: "Goal — Live",
                body: "A featured soccer fixture just moved. Open Matches to see the score.",
                date: Date().addingTimeInterval(-1_200),
                kind: .liveGoal,
                isRead: false
            ),
            AppNotification(
                title: "Full time",
                body: "A watched-style fixture finished. Check the scoreboard for the final.",
                date: Date().addingTimeInterval(-2_400),
                kind: .system,
                isRead: false
            ),
            AppNotification(
                title: "Esports slate",
                body: "CS2 and LoL maps are live in the feed.",
                date: Date().addingTimeInterval(-3_600),
                kind: .promo,
                isRead: false
            ),
            AppNotification(
                title: "Watchlist tip",
                body: "Star fixtures from match details. They stay under Profile on this iPhone.",
                date: Date().addingTimeInterval(-9_000),
                kind: .system,
                isRead: true
            ),
            AppNotification(
                title: "NBA slate live",
                body: "Several NBA games are in play with updating scores.",
                date: Date().addingTimeInterval(-14_400),
                kind: .liveGoal,
                isRead: true
            ),
            AppNotification(
                title: "Today’s fixtures",
                body: "Soccer, hockey, and tennis cards are on the Matches tab.",
                date: Date().addingTimeInterval(-18_000),
                kind: .system,
                isRead: true
            )
        ]
    }
}

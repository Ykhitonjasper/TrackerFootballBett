import Foundation

enum MockNotificationFactory {
    static func seed() -> [AppNotification] {
        [
            AppNotification(
                title: "Welcome bonus",
                body: "Demo bankroll loaded. Open tickets are already waiting in My Bets.",
                date: Date().addingTimeInterval(-900),
                kind: .promo,
                isRead: false
            ),
            AppNotification(
                title: "Goal — Live",
                body: "A featured soccer fixture just moved. Check live odds.",
                date: Date().addingTimeInterval(-1_200),
                kind: .liveGoal,
                isRead: false
            ),
            AppNotification(
                title: "Ticket settled",
                body: "One of your demo tickets finished — review P/L in My Bets.",
                date: Date().addingTimeInterval(-2_400),
                kind: .betSettled,
                isRead: false
            ),
            AppNotification(
                title: "Esports card heating up",
                body: "CS2 and LoL live maps are on the boosted rail.",
                date: Date().addingTimeInterval(-3_600),
                kind: .promo,
                isRead: false
            ),
            AppNotification(
                title: "Cash out available",
                body: "An open live ticket has a cash-out offer ready.",
                date: Date().addingTimeInterval(-4_800),
                kind: .system,
                isRead: true
            ),
            AppNotification(
                title: "Watchlist tip",
                body: "Starred fixtures are saved under Profile → Watchlist.",
                date: Date().addingTimeInterval(-9_000),
                kind: .system,
                isRead: true
            ),
            AppNotification(
                title: "Level progress",
                body: "Keep stacking tickets to unlock sharper prestige titles.",
                date: Date().addingTimeInterval(-12_000),
                kind: .levelUp,
                isRead: true
            ),
            AppNotification(
                title: "NBA slate live",
                body: "Several NBA markets are in-play with updating totals.",
                date: Date().addingTimeInterval(-14_400),
                kind: .liveGoal,
                isRead: true
            ),
            AppNotification(
                title: "Daily markets ready",
                body: "Today’s soccer, hockey, and tennis cards are seeded.",
                date: Date().addingTimeInterval(-18_000),
                kind: .system,
                isRead: true
            )
        ]
    }
}

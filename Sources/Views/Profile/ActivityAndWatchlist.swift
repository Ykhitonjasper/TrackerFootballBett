import SwiftUI
import SwiftData

struct ActivityFeedScreen: View {
    @Environment(\.modelContext) private var context
    @State private var items: [ActivityItem] = []

    var body: some View {
        List {
            if items.isEmpty {
                Text("Place or settle bets to build your activity feed.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: item.icon)
                            .foregroundStyle(item.tint)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                            Text(item.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(DateFormatters.relative.localizedString(for: item.date, relativeTo: Date()))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Activity")
        .task { reload() }
        .onReceive(NotificationCenter.default.publisher(for: .trackerBetBetPlaced)) { _ in reload() }
        .onReceive(NotificationCenter.default.publisher(for: .trackerBetSettled)) { _ in reload() }
    }

    private func reload() {
        let bets = (try? BetRepository().fetchAll(context: context)) ?? []
        items = ActivityBuilder.build(from: bets)
    }
}

struct ActivityItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let detail: String
    let date: Date
    let icon: String
    let tint: Color
}

enum ActivityBuilder {
    static func build(from bets: [Bet]) -> [ActivityItem] {
        var items: [ActivityItem] = []

        for bet in bets {
            items.append(
                ActivityItem(
                    id: UUID(),
                    title: "Bet placed",
                    detail: "\(bet.matchTitle) · \(CopyFactory.betSummary(bet))",
                    date: bet.datePlaced,
                    icon: "ticket.fill",
                    tint: AppTheme.info
                )
            )

            if let settled = bet.settledAt {
                let won = bet.outcome == .won
                items.append(
                    ActivityItem(
                        id: UUID(),
                        title: bet.outcome.rawValue,
                        detail: CopyFactory.settlementBlurb(won: won || bet.outcome == .cashedOut, payout: bet.outcome == .cashedOut ? (bet.cashOutValue ?? 0) : bet.potentialPayout),
                        date: settled,
                        icon: won ? "checkmark.circle.fill" : (bet.outcome == .cashedOut ? "arrow.down.circle.fill" : "xmark.circle.fill"),
                        tint: won ? AppTheme.accent : (bet.outcome == .cashedOut ? AppTheme.warning : AppTheme.danger)
                    )
                )
            }
        }

        return items.sorted { $0.date > $1.date }
    }
}

struct SportBreakdownScreen: View {
    @Environment(\.modelContext) private var context
    @State private var rows: [(sport: Sport, staked: Double, profit: Double, count: Int)] = []

    var body: some View {
        List {
            if rows.isEmpty {
                Text("No sport breakdown yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(rows, id: \.sport) { row in
                    HStack {
                        Image(systemName: row.sport.iconName)
                            .foregroundStyle(row.sport.accentColor)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.sport.rawValue)
                                .font(.subheadline.weight(.semibold))
                            Text("\(row.count) bets · staked \(CurrencyFormatter.compact(from: row.staked))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(CurrencyFormatter.compact(from: row.profit))
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundStyle(row.profit >= 0 ? AppTheme.accent : AppTheme.danger)
                    }
                }
            }
        }
        .navigationTitle("By sport")
        .task {
            let bets = (try? BetRepository().fetchAll(context: context)) ?? []
            rows = PerformanceAnalytics.sportBreakdown(from: bets)
        }
    }
}

struct WatchlistStore {
    private static let key = "trackerbet.watchlist"

    static func load() -> Set<UUID> {
        guard let data = UserDefaults.standard.data(forKey: key),
              let ids = try? JSONDecoder().decode([UUID].self, from: data) else {
            return []
        }
        return Set(ids)
    }

    static func save(_ ids: Set<UUID>) {
        let array = Array(ids)
        if let data = try? JSONEncoder().encode(array) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func toggle(_ id: UUID) {
        var set = load()
        if set.contains(id) {
            set.remove(id)
        } else {
            set.insert(id)
        }
        save(set)
    }

    static func contains(_ id: UUID) -> Bool {
        load().contains(id)
    }
}

struct WatchlistScreen: View {
    @Environment(\.modelContext) private var context
    @State private var matches: [Match] = []

    var body: some View {
        List {
            if matches.isEmpty {
                Text("Star matches from the detail screen to build a watchlist.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(matches) { match in
                    NavigationLink(value: match) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(match.displayName)
                                .font(.subheadline.weight(.semibold))
                            Text(CopyFactory.matchSubtitle(match))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Watchlist")
        .navigationDestination(for: Match.self) { MatchDetailScreen(match: $0) }
        .task { reload() }
        .onReceive(NotificationCenter.default.publisher(for: .trackerBetDataReset)) { _ in reload() }
    }

    private func reload() {
        let ids = WatchlistStore.load()
        let all = (try? MatchRepository().fetchAll(context: context)) ?? []
        matches = all.filter { ids.contains($0.id) }.sorted { $0.date < $1.date }
    }
}

import SwiftUI
import SwiftData

struct ActivityFeedScreen: View {
    @Environment(\.modelContext) private var context
    @State private var items: [ActivityItem] = []

    var body: some View {
        List {
            if items.isEmpty {
                Text("Follow live and finished fixtures to fill this feed.")
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
        .onReceive(NotificationCenter.default.publisher(for: .trackerBetDataReset)) { _ in reload() }
    }

    private func reload() {
        let matches = (try? MatchRepository().fetchAll(context: context)) ?? []
        items = ActivityBuilder.build(from: matches)
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
    static func build(from matches: [Match]) -> [ActivityItem] {
        var items: [ActivityItem] = []

        for match in matches {
            switch match.status {
            case .live:
                items.append(
                    ActivityItem(
                        id: match.id,
                        title: "Live · \(match.league.isEmpty ? match.sport.rawValue : match.league)",
                        detail: "\(match.displayName) · \(match.scoreLine) · \(match.clockLabel)",
                        date: match.date,
                        icon: "bolt.fill",
                        tint: AppTheme.danger
                    )
                )
            case .finished:
                items.append(
                    ActivityItem(
                        id: match.id,
                        title: "Full time",
                        detail: "\(match.displayName) finished \(match.scoreLine)",
                        date: match.date,
                        icon: "flag.checkered",
                        tint: AppTheme.accent
                    )
                )
            case .upcoming:
                items.append(
                    ActivityItem(
                        id: match.id,
                        title: "Upcoming",
                        detail: CopyFactory.matchSubtitle(match),
                        date: match.date,
                        icon: "clock.fill",
                        tint: AppTheme.info
                    )
                )
            case .postponed:
                items.append(
                    ActivityItem(
                        id: match.id,
                        title: "Postponed",
                        detail: match.displayName,
                        date: match.date,
                        icon: "pause.circle.fill",
                        tint: AppTheme.warning
                    )
                )
            }
        }

        return items.sorted { $0.date > $1.date }
    }
}

struct SportBreakdownScreen: View {
    @Environment(\.modelContext) private var context
    @State private var rows: [(sport: Sport, count: Int, live: Int)] = []

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
                            Text("\(row.count) fixtures · \(row.live) live")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("By sport")
        .task {
            let matches = (try? MatchRepository().fetchAll(context: context)) ?? []
            rows = FollowAnalytics.sportBreakdown(from: matches)
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
        Group {
            if matches.isEmpty {
                EmptyStateView(
                    title: "Nothing starred yet",
                    systemImage: "star",
                    message: "Open a fixture and tap the star to keep it here."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(matches) { match in
                            NavigationLink {
                                MatchDetailScreen(match: match)
                            } label: {
                                MatchCard(match: match)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .screenBackground()
        .navigationTitle("Watchlist")
        .navigationBarTitleDisplayMode(.large)
        .task { reload() }
        .onReceive(NotificationCenter.default.publisher(for: .trackerBetDataReset)) { _ in reload() }
    }

    private func reload() {
        let ids = WatchlistStore.load()
        let all = (try? MatchRepository().fetchAll(context: context)) ?? []
        matches = all.filter { ids.contains($0.id) }.sorted { $0.date < $1.date }
    }
}

import SwiftUI
import SwiftData

struct PicksBoardScreen: View {
    @Environment(\.modelContext) private var context
    @State private var picks: [MatchPick] = []
    @State private var filter: PickBoardFilter = .today
    @State private var market: PickMarket? = nil
    @State private var copiedCode: String?

    var body: some View {
        Group {
            if visiblePicks.isEmpty {
                EmptyStateView(
                    title: "No predictions in this filter",
                    systemImage: "lightbulb",
                    message: "Try All or another category. Match result, both to score, and goal totals live on this tab.",
                    actionTitle: "Show all"
                ) {
                    filter = .all
                    market = nil
                    reload()
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        deskStrip
                        dailyRail
                        filterBar
                        marketBar
                        ForEach(visiblePicks) { pick in
                            NavigationLink {
                                if let match = pick.match {
                                    MatchDetailScreen(match: match)
                                }
                            } label: {
                                PickCard(pick: pick, copiedCode: copiedCode) {
                                    PickClipboard.copy(pick)
                                    copiedCode = pick.code
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 20)
                }
            }
        }
        .screenBackground()
        .navigationTitle("Predictions")
        .task { reload() }
        .onReceive(NotificationCenter.default.publisher(for: .trackerBetDataReset)) { _ in reload() }
        .sensoryFeedback(.success, trigger: copiedCode)
    }

    private var visiblePicks: [MatchPick] {
        let calendar = Calendar.current
        let now = Date()
        var items = picks
        switch filter {
        case .today:
            items = items.filter { calendar.isDate($0.match?.date ?? $0.createdAt, inSameDayAs: now) }
        case .open:
            items = items.filter { $0.result == .open }
        case .settled:
            items = items.filter { $0.result != .open }
        case .all:
            break
        }
        if let market {
            items = items.filter { $0.market == market }
        }
        return items
    }

    private var deskStrip: some View {
        let snap = PickAnalytics.snapshot(from: picks)
        return HStack(spacing: 8) {
            mini("Today", "\(snap.todayCount)")
            mini("Open", "\(snap.openCount)")
            mini("Landed", "\(snap.hitCount)")
            mini("Missed", "\(snap.missCount)")
            Spacer(minLength: 0)
        }
    }

    private var dailyRail: some View {
        let top = visiblePicks.sorted { $0.confidence > $1.confidence }.prefix(8)
        return Group {
            if !top.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "Today’s sheet", subtitle: "Copy a reference code, then open the fixture")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(top)) { pick in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(pick.market.title)
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(AppTheme.accentBright)
                                    Text(pick.selectionLabel)
                                        .font(.caption.weight(.semibold))
                                        .lineLimit(2)
                                    Text(pick.code)
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(AppTheme.textTertiary)
                                }
                                .padding(10)
                                .frame(width: 148, alignment: .leading)
                                .cardStyle(elevated: true)
                            }
                        }
                    }
                }
            }
        }
    }

    private func mini(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.headline.weight(.bold).monospacedDigit())
            Text(title)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(AppTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PickBoardFilter.allCases) { item in
                    chip(item.rawValue, on: filter == item) { filter = item }
                }
            }
        }
    }

    private var marketBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All categories", on: market == nil) { market = nil }
                ForEach(PickMarket.allCases) { item in
                    chip(item.title, on: market == item) { market = item }
                }
            }
        }
    }

    private func chip(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .foregroundStyle(on ? .white : AppTheme.textSecondary)
                .background(on ? AppTheme.accent : AppTheme.surfaceElevated)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func reload() {
        PickSettler.settleAll(in: context)
        let all = (try? context.fetch(FetchDescriptor<MatchPick>())) ?? []
        picks = all.sorted { ($0.match?.date ?? $0.createdAt) < ($1.match?.date ?? $1.createdAt) }
    }
}

struct PickCard: View {
    let pick: MatchPick
    var copiedCode: String? = nil
    var onCopy: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(pick.market.title)
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .foregroundStyle(.white)
                    .background(AppTheme.accent)
                    .clipShape(Capsule())
                Text(pick.selectionLabel)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                ResultBadge(result: pick.result)
            }

            if let match = pick.match {
                Text(match.displayName)
                    .font(.subheadline.weight(.semibold))
                Text(CopyFactory.matchSubtitle(match))
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Text(pick.headline)
                .font(.headline)
            Text(pick.rationale)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Text(pick.code)
                    .font(.caption2.monospaced().weight(.semibold))
                    .foregroundStyle(AppTheme.textTertiary)
                Spacer()
                ConfidencePips(value: pick.confidence)
                if let onCopy {
                    Button(copiedCode == pick.code ? "Copied" : "Copy", action: onCopy)
                        .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        .padding(14)
        .cardStyle(elevated: true)
    }
}

struct LeanBadge: View {
    let lean: PickLean
    var team: String = ""

    var body: some View {
        Text(team.isEmpty ? lean.shortLabel : "\(lean.shortLabel) · \(team)")
            .font(.caption2.weight(.bold))
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(.white)
            .background(AppTheme.accent)
            .clipShape(Capsule())
    }
}

struct ResultBadge: View {
    let result: PickResult

    var body: some View {
        Text(result.rawValue.uppercased())
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(color)
            .background(color.opacity(0.16))
            .clipShape(Capsule())
    }

    private var color: Color {
        switch result {
        case .open: return AppTheme.highlight
        case .hit: return AppTheme.success
        case .miss: return AppTheme.danger
        case .void: return AppTheme.textSecondary
        }
    }
}

struct ConfidencePips: View {
    let value: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { pip in
                Capsule()
                    .fill(pip <= value ? AppTheme.accentBright : AppTheme.border)
                    .frame(width: 10, height: 6)
            }
        }
        .accessibilityLabel("Confidence \(value) of 5")
    }
}

#Preview {
    NavigationStack { PicksBoardScreen() }
        .modelContainer(for: [UserProfile.self, Match.self, MatchPick.self], inMemory: true)
}

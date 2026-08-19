import SwiftUI
import SwiftData

struct MatchFeedScreen: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel = MatchFeedViewModel()
    @State private var showNotifications = false
    @StateObject private var notifications = NotificationService.shared

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView("Loading fixtures…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .empty:
                EmptyStateView(
                    title: "No matches",
                    systemImage: "sportscourt",
                    message: "Try another sport or status filter.",
                    actionTitle: "Reset filters"
                ) {
                    viewModel.selectedSport = nil
                    viewModel.statusFilter = .all
                    viewModel.load(context: context)
                }
            case .error(let message):
                EmptyStateView(
                    title: "Something went wrong",
                    systemImage: "exclamationmark.triangle",
                    message: message,
                    actionTitle: "Retry"
                ) {
                    viewModel.load(context: context)
                }
            case .loaded(let matches):
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        searchField
                        densityStrip(matches)
                        SportFilterBar(selected: viewModel.selectedSport) { sport in
                            viewModel.applySport(sport, context: context)
                        }
                        StatusFilterBar(selected: $viewModel.statusFilter) {
                            viewModel.load(context: context)
                        }
                        sortRow
                        promoStrip

                        if !viewModel.featured.isEmpty && viewModel.selectedSport == nil && viewModel.statusFilter == .all && viewModel.searchQuery.isEmpty {
                            featuredSection
                            liveRail(matches)
                        }

                        ForEach(FeedSectioning.group(matches)) { section in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(section.title)
                                        .font(.subheadline.weight(.bold))
                                    Spacer()
                                    Text("\(section.matches.count)")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(AppTheme.textTertiary)
                                }
                                .padding(.horizontal, 16)

                                LazyVStack(spacing: 8) {
                                    ForEach(section.matches) { match in
                                        NavigationLink(value: match) {
                                            MatchCard(match: match)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 6)
                }
                .refreshable { viewModel.refresh(context: context) }
            }
        }
        .screenBackground()
        .navigationTitle("Matches")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNotifications = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                        if notifications.unreadCount > 0 {
                            Text("\(min(9, notifications.unreadCount))")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(4)
                                .background(AppTheme.danger)
                                .clipShape(Circle())
                                .offset(x: 8, y: -8)
                        }
                    }
                }
            }
        }
        .navigationDestination(for: Match.self) { match in
            MatchDetailScreen(match: match)
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsScreen()
        }
        .onAppear { viewModel.load(context: context) }
        .onReceive(NotificationCenter.default.publisher(for: .trackerBetDataReset)) { _ in
            viewModel.load(context: context)
        }
    }

    private func densityStrip(_ matches: [Match]) -> some View {
        let live = matches.filter { $0.status == .live }.count
        let up = matches.filter { $0.status == .upcoming }.count
        let done = matches.filter { $0.status == .finished }.count
        return HStack(spacing: 8) {
            chip("\(matches.count) fixtures", AppTheme.accent)
            chip("\(live) live", AppTheme.danger)
            chip("\(up) soon", AppTheme.highlight)
            chip("\(done) FT", AppTheme.textSecondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
    }

    private func chip(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(color.opacity(0.14))
            .clipShape(Capsule())
    }

    private var promoStrip: some View {
        HStack(spacing: 10) {
            Image(systemName: "flame.fill")
                .foregroundStyle(AppTheme.highlight)
            VStack(alignment: .leading, spacing: 2) {
                Text("Predictions")
                    .font(.caption.weight(.bold))
                Text("Daily match result, both to score, and goal totals — open the Predictions tab")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            Text("HOT")
                .font(.caption2.weight(.black))
                .foregroundStyle(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppTheme.highlight)
                .clipShape(Capsule())
        }
        .padding(12)
        .background(AppTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
    }

    private func liveRail(_ matches: [Match]) -> some View {
        let live = matches.filter { $0.status == .live }
        guard !live.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Live now", subtitle: "In-play scores")
                    .padding(.horizontal, 16)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(live.prefix(10)) { match in
                            NavigationLink(value: match) {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Circle().fill(AppTheme.danger).frame(width: 6, height: 6)
                                        Text(match.clockLabel)
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(AppTheme.danger)
                                    }
                                    Text("\(match.homeTeam) \(match.homeScore)")
                                        .font(.caption.weight(.semibold))
                                        .lineLimit(1)
                                    Text("\(match.awayTeam) \(match.awayScore)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AppTheme.textSecondary)
                                        .lineLimit(1)
                                    Text(match.league.isEmpty ? match.sport.rawValue : match.league)
                                        .font(.caption2.monospacedDigit().weight(.bold))
                                        .foregroundStyle(AppTheme.accentBright)
                                }
                                .padding(10)
                                .frame(width: 150, alignment: .leading)
                                .cardStyle(elevated: true)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        )
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.textSecondary)
            TextField("Search teams or leagues", text: $viewModel.searchQuery)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit { viewModel.load(context: context) }
            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                    viewModel.load(context: context)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
        }
        .padding(10)
        .background(AppTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusM, style: .continuous))
        .padding(.horizontal, 16)
    }

    private var sortRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Text("Sort")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                ForEach(SortOption.allCases) { option in
                    Button {
                        viewModel.applySort(option, context: context)
                    } label: {
                        Text(option.rawValue)
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(viewModel.sortOption == option ? AppTheme.accentMuted : AppTheme.surface)
                            .foregroundStyle(viewModel.sortOption == option ? AppTheme.accent : AppTheme.textSecondary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Featured", subtitle: "Top fixtures")
                .padding(.horizontal, 16)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.featured.prefix(10)) { match in
                        NavigationLink(value: match) {
                            FeaturedMatchCard(match: match)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

struct FeaturedMatchCard: View {
    let match: Match

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(match.sport.shortLabel, systemImage: match.sport.iconName)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(match.sport.accentColor)
                Spacer()
                StatusBadge(status: match.status)
            }
            Text(match.homeTeam)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            Text(match.awayTeam)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(AppTheme.textSecondary)
            HStack {
                Text(match.clockLabel)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text(match.sport.shortLabel)
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.accentBright)
            }
        }
        .padding(10)
        .frame(width: 168)
        .cardStyle(elevated: true)
    }
}

struct MatchCard: View {
    let match: Match

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                LeagueBadge(leagueName: match.league)
                Text(match.league.isEmpty ? match.sport.rawValue : match.league)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
                Spacer()
                StatusBadge(status: match.status)
            }

            HStack(alignment: .center) {
                Text(match.homeTeam)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 2) {
                    Text(match.status == .upcoming ? DateFormatters.kickoff.string(from: match.date) : match.scoreLine)
                        .font(.headline.weight(.bold).monospacedDigit())
                    Text(match.clockLabel)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(match.status == .live ? AppTheme.danger : AppTheme.textSecondary)
                }
                .frame(width: 72)
                Text(match.awayTeam)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .multilineTextAlignment(.trailing)
            }

            HStack(spacing: 6) {
                Label(match.sport.rawValue, systemImage: match.sport.iconName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(match.sport.accentColor)
                Spacer()
                if let pick = match.primaryPick {
                    Text(pick.market.title)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppTheme.accentBright)
                } else if !match.venue.isEmpty {
                    Text(match.venue)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(10)
        .cardStyle()
    }
}

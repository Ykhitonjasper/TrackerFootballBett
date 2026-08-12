import SwiftUI
import SwiftData

struct ProfileScreen: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel = ProfileViewModel()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView("Loading profile…")
                case .error(let message):
                    EmptyStateView(
                        title: "Profile unavailable",
                        systemImage: "person.crop.circle.badge.exclamationmark",
                        message: message,
                        actionTitle: "Retry"
                    ) { viewModel.load(context: context) }
                case .empty:
                    EmptyStateView(title: "No profile", systemImage: "person", message: "Create a profile from onboarding.")
                case .loaded(let user):
                    ScrollView {
                        VStack(spacing: 18) {
                            BalanceCard(
                                balance: user.balance,
                                username: user.username,
                                levelTitle: "Lv \(user.level) · \(user.displayLevelTitle)",
                                progress: user.experienceProgress
                            )

                            if let dashboard = viewModel.dashboard {
                                PerformanceDashboard(snapshot: dashboard.snapshot, series: dashboard.series)
                            }

                            CoachTipsCard(
                                balance: user.balance,
                                pendingCount: viewModel.dashboard?.snapshot.pendingCount ?? 0,
                                netProfit: user.netProfit
                            )

                            if !viewModel.recentTickets.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    SectionHeader(title: "Recent tickets", subtitle: "Jump back into My Bets")
                                    ForEach(viewModel.recentTickets.prefix(4)) { bet in
                                        NavigationLink {
                                            BetDetailScreen(bet: bet)
                                        } label: {
                                            BetCard(bet: bet)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                StatCard(title: "Total Bets", value: "\(viewModel.totalBetsPlaced)", icon: "ticket.fill")
                                StatCard(title: "Win Rate", value: String(format: "%.0f%%", viewModel.winRate), icon: "chart.line.uptrend.xyaxis")
                                StatCard(title: "Net Profit", value: CurrencyFormatter.compact(from: user.netProfit), icon: "dollarsign.circle.fill", tint: user.netProfit >= 0 ? AppTheme.accent : AppTheme.danger)
                                StatCard(title: "Rank", value: viewModel.rankLabel, icon: "trophy.fill", tint: AppTheme.warning)
                                StatCard(title: "Best Win", value: CurrencyFormatter.compact(from: viewModel.bestWin), icon: "flame.fill", tint: .orange)
                                StatCard(title: "Win Streak", value: "\(viewModel.currentStreak)", icon: "bolt.fill", tint: .cyan)
                                StatCard(title: "Avg Odds", value: String(format: "%.2f", viewModel.avgOdds), icon: "number")
                                StatCard(title: "Favorite", value: user.favoriteSport.shortLabel, icon: user.favoriteSport.iconName, tint: user.favoriteSport.accentColor)
                            }

                            NavigationLink {
                                HelpScreen()
                            } label: {
                                HStack {
                                    Image(systemName: "questionmark.circle.fill")
                                    Text("How Tracker Football Bett works")
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(AppTheme.textTertiary)
                                }
                                .padding(14)
                                .cardStyle()
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                ActivityFeedScreen()
                            } label: {
                                HStack {
                                    Image(systemName: "list.bullet.rectangle.portrait.fill")
                                    Text("Activity")
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(AppTheme.textTertiary)
                                }
                                .padding(14)
                                .cardStyle()
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                SportBreakdownScreen()
                            } label: {
                                HStack {
                                    Image(systemName: "chart.pie.fill")
                                    Text("Breakdown by sport")
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(AppTheme.textTertiary)
                                }
                                .padding(14)
                                .cardStyle()
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                WatchlistScreen()
                            } label: {
                                HStack {
                                    Image(systemName: "star.circle.fill")
                                    Text("Watchlist")
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(AppTheme.textTertiary)
                                }
                                .padding(14)
                                .cardStyle()
                            }
                            .buttonStyle(.plain)

                            Button {
                                showSettings = true
                            } label: {
                                HStack {
                                    Image(systemName: "gearshape.fill")
                                    Text("Settings")
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(AppTheme.textTertiary)
                                }
                                .padding(14)
                                .cardStyle()
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(16)
                    }
                }
            }
            .screenBackground()
            .navigationTitle("Profile")
            .sheet(isPresented: $showSettings) {
                SettingsScreen(viewModel: viewModel)
            }
            .task { viewModel.load(context: context) }
            .onReceive(NotificationCenter.default.publisher(for: .trackerBetBetPlaced)) { _ in
                viewModel.load(context: context)
            }
            .onReceive(NotificationCenter.default.publisher(for: .trackerBetSettled)) { _ in
                viewModel.load(context: context)
            }
        }
    }
}

struct SettingsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Bindable var viewModel: ProfileViewModel
    @State private var confirmReset = false
    @State private var confirmDeleteAll = false

    var body: some View {
        NavigationStack {
            Form {
                if case .loaded(let user) = viewModel.state {
                    Section("Preferences") {
                        Toggle("Notifications", isOn: Binding(
                            get: { user.notificationsEnabled },
                            set: { viewModel.updatePreferences(notifications: $0, sound: user.soundEnabled, context: context) }
                        ))
                        Toggle("Sounds", isOn: Binding(
                            get: { user.soundEnabled },
                            set: { viewModel.updatePreferences(notifications: user.notificationsEnabled, sound: $0, context: context) }
                        ))
                    }

                    Section("Account") {
                        LabeledContent("Username", value: user.username)
                        LabeledContent("Member since", value: DateFormatters.shortDate.string(from: user.createdAt))
                        LabeledContent("Starting bankroll", value: CurrencyFormatter.string(from: user.startingBalance))
                    }
                }

                Section("Legal") {
                    Link("Privacy Policy", destination: LegalLinks.privacy)
                    Link("Terms of Use", destination: LegalLinks.terms)
                    Link("Support", destination: LegalLinks.support)
                }

                Section("Demo") {
                    Button("Reset demo data", role: .destructive) {
                        confirmReset = true
                    }
                    Button("Delete all data", role: .destructive) {
                        confirmDeleteAll = true
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Build", value: "1")
                    Text("Tracker Football Bett is a paper-betting simulation. No real-money gambling, deposits, or payouts.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Reset all demo data?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset", role: .destructive) {
                    viewModel.resetDemo(context: context)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This restores the starter bankroll, clears bets, and reloads match fixtures.")
            }
            .confirmationDialog("Delete all local data?", isPresented: $confirmDeleteAll, titleVisibility: .visible) {
                Button("Delete Everything", role: .destructive) {
                    viewModel.resetDemo(context: context)
                    WatchlistStore.save([])
                    hasCompletedOnboarding = false
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Clears tickets, fixtures, watchlist and returns you to onboarding.")
            }
        }
    }
}

struct LeaderboardScreen: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel = LeaderboardViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView("Loading ranks…")
            case .empty:
                EmptyStateView(title: "No rankings", systemImage: "trophy", message: "Place bets to join the ladder.")
            case .error(let message):
                EmptyStateView(title: "Leaderboard error", systemImage: "exclamationmark.triangle", message: message, actionTitle: "Retry") {
                    viewModel.load(context: context)
                }
            case .loaded(let entries):
                List {
                    if let mine = viewModel.userRank {
                        Section("Your position") {
                            LeaderboardRow(entry: mine, highlight: true)
                        }
                    }
                    Section("Weekly ladder") {
                        ForEach(entries) { entry in
                            LeaderboardRow(entry: entry, highlight: entry.isCurrentUser)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable { viewModel.load(context: context) }
            }
        }
        .screenBackground()
        .navigationTitle("Leaderboard")
        .task { viewModel.load(context: context) }
        .onReceive(NotificationCenter.default.publisher(for: .trackerBetSettled)) { _ in
            viewModel.load(context: context)
        }
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    var highlight: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Text(rankText)
                .font(.headline.monospacedDigit())
                .foregroundStyle(rankColor)
                .frame(width: 36, alignment: .leading)

            Circle()
                .fill(entry.color.gradient)
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(entry.username.prefix(1)).uppercased())
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(entry.username)
                        .font(.subheadline.weight(.semibold))
                    if entry.isCurrentUser {
                        Text("YOU")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.accentMuted)
                            .foregroundStyle(AppTheme.accent)
                            .clipShape(Capsule())
                    }
                }
                Text("\(entry.totalBets) bets · \(Int(entry.winRate * 100))% WR")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Text("\(entry.points)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(entry.points >= 0 ? AppTheme.accent : AppTheme.danger)
        }
        .padding(.vertical, 4)
        .listRowBackground(highlight ? AppTheme.accent.opacity(0.08) : nil)
    }

    private var rankText: String {
        "#\(entry.rank)"
    }

    private var rankColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return AppTheme.textSecondary
        }
    }
}

struct NotificationsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = NotificationsViewModel()

    var body: some View {
        NavigationStack {
            List {
                if viewModel.items.isEmpty {
                    Text("No notifications")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.items) { item in
                        Button {
                            viewModel.markRead(item.id)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: item.kind.icon)
                                    .foregroundStyle(AppTheme.accent)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(item.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.primary)
                                        if !item.isRead {
                                            Circle()
                                                .fill(AppTheme.accent)
                                                .frame(width: 8, height: 8)
                                        }
                                    }
                                    Text(item.body)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.leading)
                                    Text(DateFormatters.relative.localizedString(for: item.date, relativeTo: Date()))
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Notifications")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Mark all read") { viewModel.markAllRead() }
                        .disabled(viewModel.unreadCount == 0)
                }
            }
        }
    }
}

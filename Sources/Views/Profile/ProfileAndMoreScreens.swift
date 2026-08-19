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
                            ProfileHeaderCard(
                                displayName: user.displayName,
                                favoriteSport: user.favoriteSport.rawValue
                            )

                            if let dashboard = viewModel.dashboard {
                                FollowDashboard(snapshot: dashboard.snapshot, series: dashboard.series)
                            }

                            CoachTipsCard(watchCount: viewModel.watchCount, liveCount: viewModel.liveCount)

                            if !viewModel.recentWatched.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    SectionHeader(title: "Watching now", subtitle: "Jump back into starred fixtures")
                                    ForEach(viewModel.recentWatched.prefix(4)) { match in
                                        NavigationLink {
                                            MatchDetailScreen(match: match)
                                        } label: {
                                            MatchCard(match: match)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                StatCard(title: "Watching", value: "\(viewModel.watchCount)", icon: "star.fill")
                                StatCard(title: "Open", value: "\(viewModel.openPicks)", icon: "lightbulb.fill", tint: AppTheme.highlight)
                                StatCard(title: "Landed", value: "\(viewModel.hitPicks)", icon: "checkmark.circle.fill", tint: AppTheme.success)
                                StatCard(title: "Live now", value: "\(viewModel.liveCount)", icon: "bolt.fill", tint: AppTheme.danger)
                                StatCard(title: "Favorite", value: user.favoriteSport.shortLabel, icon: user.favoriteSport.iconName, tint: user.favoriteSport.accentColor)
                            }

                            NavigationLink {
                                HelpScreen()
                            } label: {
                                HStack {
                                    Image(systemName: "questionmark.circle.fill")
                                    Text("How Match Journal works")
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
            .onReceive(NotificationCenter.default.publisher(for: .trackerBetDataReset)) { _ in
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

                    Section("Profile") {
                        LabeledContent("Display name", value: user.displayName)
                        LabeledContent("Member since", value: DateFormatters.shortDate.string(from: user.createdAt))
                        LabeledContent("Favorite sport", value: user.favoriteSport.rawValue)
                    }
                }

                Section("Legal") {
                    Link("Privacy Policy", destination: LegalLinks.privacy)
                    Link("Terms of Use", destination: LegalLinks.terms)
                    Link("Upcoming updates", destination: LegalLinks.updates)
                    Link("Support", destination: LegalLinks.support)
                }

                Section("Data") {
                    Button("Reload fixtures", role: .destructive) {
                        confirmReset = true
                    }
                    Button("Delete all data", role: .destructive) {
                        confirmDeleteAll = true
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Build", value: "8")
                    Text("Match Journal is a local match journal with live scores, form, and a personal watchlist. Everything stays on this device.")
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
            .confirmationDialog("Reload the fixture slate?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reload", role: .destructive) {
                    viewModel.resetLocalData(context: context)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This restores the fixture slate and a local profile.")
            }
            .confirmationDialog("Delete all local data?", isPresented: $confirmDeleteAll, titleVisibility: .visible) {
                Button("Delete Everything", role: .destructive) {
                    viewModel.resetLocalData(context: context)
                    WatchlistStore.save([])
                    hasCompletedOnboarding = false
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Clears fixtures, watchlist and returns you to onboarding.")
            }
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

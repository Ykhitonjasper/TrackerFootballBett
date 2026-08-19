import SwiftUI

struct StatusBadge: View {
    let status: MatchStatus

    var body: some View {
        HStack(spacing: 6) {
            if status == .live {
                Circle()
                    .fill(status.badgeColor)
                    .frame(width: 6, height: 6)
                    .overlay(
                        Circle()
                            .stroke(status.badgeColor.opacity(0.5), lineWidth: 4)
                            .scaleEffect(1.4)
                            .opacity(0.6)
                    )
            }
            Text(status.rawValue.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(0.6)
        }
        .foregroundStyle(status == .live ? status.badgeColor : AppTheme.textSecondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.badgeColor.opacity(status == .live ? 0.15 : 0.12))
        .clipShape(Capsule())
    }
}

struct SportFilterBar: View {
    let selected: Sport?
    let onSelect: (Sport?) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "All", icon: "square.grid.2x2.fill", sport: nil)
                ForEach(Sport.allCases) { sport in
                    filterChip(title: sport.rawValue, icon: sport.iconName, sport: sport)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func filterChip(title: String, icon: String, sport: Sport?) -> some View {
        let isOn = selected == sport
        return Button {
            onSelect(sport)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(isOn ? .white : AppTheme.textSecondary)
            .background(isOn ? (sport?.accentColor ?? AppTheme.accent) : AppTheme.surfaceElevated)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct StatusFilterBar: View {
    @Binding var selected: FeedStatusFilter
    let onChange: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(FeedStatusFilter.allCases) { filter in
                Button {
                    selected = filter
                    onChange()
                } label: {
                    Text(filter.rawValue)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .foregroundStyle(selected == filter ? .white : AppTheme.textSecondary)
                        .background(selected == filter ? AppTheme.accent : AppTheme.surfaceElevated)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var tint: Color = AppTheme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text(value)
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .cardStyle()
    }
}

struct ProfileHeaderCard: View {
    let displayName: String
    let favoriteSport: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(.title2.weight(.bold))
                    Text(favoriteSport)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(.white.opacity(0.85))
            }

            Text("Match Journal")
                .font(.system(size: 22, weight: .bold, design: .rounded))

            Text("Today’s predictions are ready")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(AppTheme.headerCardGradient)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusXL, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusXL, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }
}

struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

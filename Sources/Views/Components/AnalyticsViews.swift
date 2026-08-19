import SwiftUI

struct InsightsCard: View {
    let match: Match

    private var insights: [MatchInsightEngine.Insight] {
        MatchInsightEngine.insights(for: match)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Match notes", subtitle: "Scoreboard context for this fixture")
            ForEach(insights) { insight in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(color(for: insight.sentiment))
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(insight.title)
                            .font(.subheadline.weight(.semibold))
                        Text(insight.detail)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
        }
        .padding(14)
        .cardStyle()
    }

    private func color(for sentiment: MatchInsightEngine.Insight.Sentiment) -> Color {
        switch sentiment {
        case .positive: return AppTheme.accent
        case .neutral: return AppTheme.info
        case .caution: return AppTheme.warning
        }
    }
}

struct FollowDashboard: View {
    let snapshot: FollowAnalytics.Snapshot
    let series: [(date: Date, count: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Your journal", subtitle: "Predictions and fixtures on this device")

            HStack(spacing: 10) {
                miniStat("Live", "\(snapshot.liveCount)", AppTheme.danger)
                miniStat("Soon", "\(snapshot.upcomingCount)", AppTheme.info)
                miniStat("Watching", "\(snapshot.watchedCount)", AppTheme.warning)
            }

            if series.count > 1 {
                GeometryReader { geo in
                    let values = series.map(\.count)
                    let maxV = max(values.max() ?? 1, 1)

                    Path { path in
                        for (index, point) in series.enumerated() {
                            let x = geo.size.width * CGFloat(index) / CGFloat(max(series.count - 1, 1))
                            let y = geo.size.height * (1 - CGFloat(Double(point.count) / Double(maxV)))
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(AppTheme.accent, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
                }
                .frame(height: 90)
                .padding(.vertical, 4)
            }

            if let sport = snapshot.topSport {
                Text("Most followed sport: \(sport.rawValue)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Text("\(snapshot.sportsCovered) sports · \(snapshot.fixtureCount) fixtures")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(14)
        .cardStyle(elevated: true)
    }

    private func miniStat(_ title: String, _ value: String, _ tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(AppTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

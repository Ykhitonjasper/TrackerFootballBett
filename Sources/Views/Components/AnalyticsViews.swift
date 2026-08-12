import SwiftUI

struct InsightsCard: View {
    let match: Match

    private var insights: [MatchInsightEngine.Insight] {
        MatchInsightEngine.insights(for: match)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Insights", subtitle: "Demo analysis from live prices")
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

struct PerformanceDashboard: View {
    let snapshot: PerformanceAnalytics.Snapshot
    let series: [(date: Date, profit: Double)]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Performance", subtitle: "Paper bankroll analytics")

            HStack(spacing: 10) {
                miniStat("ROI", String(format: "%.0f%%", snapshot.roi * 100), snapshot.roi >= 0 ? AppTheme.accent : AppTheme.danger)
                miniStat("Avg stake", CurrencyFormatter.compact(from: snapshot.averageStake), AppTheme.info)
                miniStat("Pending", "\(snapshot.pendingCount)", AppTheme.warning)
            }

            if series.count > 1 {
                GeometryReader { geo in
                    let values = series.map(\.profit)
                    let minV = (values.min() ?? 0) - 1
                    let maxV = (values.max() ?? 0) + 1
                    let range = max(maxV - minV, 1)

                    Path { path in
                        for (index, point) in series.enumerated() {
                            let x = geo.size.width * CGFloat(index) / CGFloat(max(series.count - 1, 1))
                            let y = geo.size.height * (1 - CGFloat((point.profit - minV) / range))
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

            if let sport = snapshot.bestSport {
                Text("Best sport: \(sport.rawValue)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            if let market = snapshot.hottestMarket {
                Text("Most used market: \(market.rawValue)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
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

struct SuggestedStakeHint: View {
    let balance: Double
    let odds: Double
    let onApply: (Double) -> Void

    private var suggestion: Double {
        BankrollMath.suggestedStake(balance: balance, odds: odds)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Suggested stake")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                Text(CurrencyFormatter.string(from: suggestion))
                    .font(.subheadline.weight(.bold))
            }
            Spacer()
            Button("Use") { onApply(suggestion) }
                .buttonStyle(SecondaryButtonStyle())
        }
        .padding(12)
        .background(AppTheme.accentMuted)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusM, style: .continuous))
    }
}

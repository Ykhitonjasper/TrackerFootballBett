import SwiftUI

struct PriceMovementChart: View {
    let ticks: [PriceMovementSimulator.Tick]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Price movement")
                    .font(.headline)
                Spacer()
                Text("vol \(PriceMovementSimulator.volatilityScore(for: ticks))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(AppTheme.textSecondary)
            }

            GeometryReader { geo in
                let homes = ticks.map(\.home)
                let minV = (homes.min() ?? 1) - 0.1
                let maxV = (homes.max() ?? 2) + 0.1
                let range = max(maxV - minV, 0.2)

                ZStack {
                    ForEach(0..<4, id: \.self) { line in
                        let y = geo.size.height * CGFloat(line) / 3
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geo.size.width, y: y))
                        }
                        .stroke(AppTheme.border, lineWidth: 1)
                    }

                    Path { path in
                        for (index, tick) in ticks.enumerated() {
                            let x = geo.size.width * CGFloat(index) / CGFloat(max(ticks.count - 1, 1))
                            let y = geo.size.height * (1 - CGFloat((tick.home - minV) / range))
                            if index == 0 { path.move(to: CGPoint(x: x, y: y)) }
                            else { path.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .stroke(AppTheme.accent, lineWidth: 2)

                    Path { path in
                        for (index, tick) in ticks.enumerated() {
                            let x = geo.size.width * CGFloat(index) / CGFloat(max(ticks.count - 1, 1))
                            let y = geo.size.height * (1 - CGFloat((tick.away - minV) / range))
                            if index == 0 { path.move(to: CGPoint(x: x, y: y)) }
                            else { path.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .stroke(Color.red.opacity(0.8), lineWidth: 2)
                }
            }
            .frame(height: 110)

            HStack {
                legend(color: AppTheme.accent, title: "Home")
                legend(color: .red.opacity(0.8), title: "Away")
                Spacer()
            }
        }
        .padding(14)
        .cardStyle()
    }

    private func legend(color: Color, title: String) -> some View {
        HStack(spacing: 6) {
            Capsule().fill(color).frame(width: 14, height: 4)
            Text(title).font(.caption2).foregroundStyle(AppTheme.textSecondary)
        }
    }
}

struct RiskMeterBadge: View {
    let stake: Double
    let balance: Double
    let odds: Double

    private var band: TicketRiskMeter.Band {
        TicketRiskMeter.band(stake: stake, balance: balance, odds: odds)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Risk profile")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            Text(band.rawValue)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color(hex: TicketRiskMeter.color(for: band)) ?? AppTheme.textPrimary)
            Text(band.detail)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

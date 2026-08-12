import Foundation

/// Lightweight analytics + history helpers for the demo app.
enum PerformanceAnalytics {
    struct Snapshot: Hashable {
        var betsPlaced: Int
        var winCount: Int
        var lossCount: Int
        var cashOutCount: Int
        var pendingCount: Int
        var totalStaked: Double
        var totalReturned: Double
        var netProfit: Double
        var averageOdds: Double
        var averageStake: Double
        var roi: Double
        var bestSport: Sport?
        var hottestMarket: BetType?

        var winRate: Double {
            let settled = winCount + lossCount
            guard settled > 0 else { return 0 }
            return Double(winCount) / Double(settled)
        }
    }

    static func snapshot(from bets: [Bet]) -> Snapshot {
        let win = bets.filter { $0.outcome == .won }
        let loss = bets.filter { $0.outcome == .lost }
        let cash = bets.filter { $0.outcome == .cashedOut }
        let pending = bets.filter { $0.outcome == .pending }

        let staked = bets.reduce(0.0) { $0 + $1.amount }
        let returned = bets.reduce(0.0) { partial, bet in
            switch bet.outcome {
            case .won: return partial + bet.potentialPayout
            case .cashedOut: return partial + (bet.cashOutValue ?? 0)
            case .void: return partial + bet.amount
            default: return partial
            }
        }
        let net = bets.reduce(0.0) { $0 + $1.realizedProfit }
        let avgOdds = bets.isEmpty ? 0 : bets.reduce(0.0) { $0 + $1.odds } / Double(bets.count)
        let avgStake = bets.isEmpty ? 0 : staked / Double(bets.count)
        let roi = staked == 0 ? 0 : net / staked

        return Snapshot(
            betsPlaced: bets.count,
            winCount: win.count,
            lossCount: loss.count,
            cashOutCount: cash.count,
            pendingCount: pending.count,
            totalStaked: staked,
            totalReturned: returned,
            netProfit: net,
            averageOdds: avgOdds,
            averageStake: avgStake,
            roi: roi,
            bestSport: bestSport(in: bets),
            hottestMarket: hottestMarket(in: bets)
        )
    }

    static func profitSeries(from bets: [Bet], days: Int = 14) -> [(date: Date, profit: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var running = 0.0
        var series: [(Date, Double)] = []

        for offset in (0..<days).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let dayBets = bets.filter { calendar.isDate($0.settledAt ?? $0.datePlaced, inSameDayAs: day) }
            running += dayBets.reduce(0) { $0 + $1.realizedProfit }
            series.append((day, running))
        }
        return series
    }

    static func sportBreakdown(from bets: [Bet]) -> [(sport: Sport, staked: Double, profit: Double, count: Int)] {
        var map: [Sport: (Double, Double, Int)] = [:]
        for bet in bets {
            guard let sport = bet.match?.sport else { continue }
            let current = map[sport] ?? (0, 0, 0)
            map[sport] = (current.0 + bet.amount, current.1 + bet.realizedProfit, current.2 + 1)
        }
        return map
            .map { (sport: $0.key, staked: $0.value.0, profit: $0.value.1, count: $0.value.2) }
            .sorted { $0.staked > $1.staked }
    }

    private static func bestSport(in bets: [Bet]) -> Sport? {
        sportBreakdown(from: bets)
            .filter { $0.count >= 1 }
            .max(by: { $0.profit < $1.profit })?
            .sport
    }

    private static func hottestMarket(in bets: [Bet]) -> BetType? {
        var counts: [BetType: Int] = [:]
        for bet in bets {
            counts[bet.type, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}

enum BankrollMath {
    static func kellyFraction(odds: Double, winProbability: Double) -> Double {
        guard odds > 1, winProbability > 0, winProbability < 1 else { return 0 }
        let b = odds - 1
        let q = 1 - winProbability
        let fraction = (b * winProbability - q) / b
        return max(0, min(0.25, fraction))
    }

    static func suggestedStake(balance: Double, odds: Double, estimatedEdge: Double = 0.03) -> Double {
        let fairProb = OddsCalculator.impliedProbability(odds) + estimatedEdge
        let fraction = kellyFraction(odds: odds, winProbability: min(0.85, fairProb))
        let raw = balance * fraction
        return max(5, min(balance * 0.2, (raw * 100).rounded() / 100))
    }

    static func units(stake: Double, baseUnit: Double = 10) -> Double {
        guard baseUnit > 0 else { return 0 }
        return (stake / baseUnit * 10).rounded() / 10
    }
}

enum MatchInsightEngine {
    struct Insight: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let detail: String
        let sentiment: Sentiment

        enum Sentiment: String { case positive, neutral, caution }
    }

    static func insights(for match: Match) -> [Insight] {
        var items: [Insight] = []

        let homeImplied = OddsCalculator.impliedProbability(match.homeOdds)
        let awayImplied = OddsCalculator.impliedProbability(match.awayOdds)

        if homeImplied > awayImplied + 0.08 {
            items.append(Insight(title: "Home favored", detail: "\(match.homeTeam) carries the sharper price side of this market.", sentiment: .positive))
        } else if awayImplied > homeImplied + 0.08 {
            items.append(Insight(title: "Away favored", detail: "\(match.awayTeam) is priced as the more likely winner.", sentiment: .positive))
        } else {
            items.append(Insight(title: "Toss-up pricing", detail: "Moneyline prices are relatively balanced.", sentiment: .neutral))
        }

        if match.status == .live {
            items.append(Insight(title: "Live volatility", detail: "In-play odds can swing quickly as the clock advances.", sentiment: .caution))
            if abs(match.homeScore - match.awayScore) >= 2 {
                items.append(Insight(title: "Score gap", detail: "Double-chance or totals markets may offer better value than the moneyline.", sentiment: .neutral))
            }
        }

        if match.isFeatured {
            items.append(Insight(title: "Featured fixture", detail: "Higher liquidity and public attention usually mean sharper lines.", sentiment: .neutral))
        }

        if match.popularity >= 90 {
            items.append(Insight(title: "High interest", detail: "Expect heavier betting volume on this card.", sentiment: .positive))
        }

        if match.sport.allowsDraw, let draw = match.drawOdds, draw < 3.1 {
            items.append(Insight(title: "Draw in play", detail: "Draw odds are relatively short for this matchup.", sentiment: .caution))
        }

        return items
    }
}

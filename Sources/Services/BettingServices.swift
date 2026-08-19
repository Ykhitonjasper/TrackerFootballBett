import Foundation
import SwiftData

@MainActor
final class LiveMatchSimulator {
    static let shared = LiveMatchSimulator()

    private var timer: Timer?
    private weak var context: ModelContext?

    func start(context: ModelContext) {
        self.context = context
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 12, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        context = nil
    }

    private func tick() {
        guard let context else { return }
        do {
            let matches = try context.fetch(FetchDescriptor<Match>())
            for match in matches {
                switch match.status {
                case .upcoming:
                    if match.date <= Date() {
                        match.status = .live
                        match.minute = 1
                    }
                case .live:
                    advanceLive(match)
                    if match.status == .finished {
                        (match.picks ?? []).forEach(PickSettler.settle)
                    }
                case .finished, .postponed:
                    break
                }
            }
            try context.save()
        } catch {}
    }

    private func advanceLive(_ match: Match) {
        match.minute = min(95, match.minute + Int.random(in: 2...5))

        let scoringChance: Double
        switch match.sport {
        case .soccer, .hockey: scoringChance = 0.28
        case .basketball: scoringChance = 0.75
        case .tennis: scoringChance = 0.45
        case .baseball: scoringChance = 0.35
        case .esports: scoringChance = 0.40
        }

        if Double.random(in: 0...1) < scoringChance {
            if Bool.random() {
                match.homeScore += scoreIncrement(for: match.sport)
            } else {
                match.awayScore += scoreIncrement(for: match.sport)
            }
        }

        if match.minute >= 90 || (match.sport != .soccer && match.sport != .hockey && match.minute >= 48) {
            if Double.random(in: 0...1) < 0.35 {
                match.status = .finished
                match.minute = match.sport == .soccer || match.sport == .hockey ? 90 : match.minute
            }
        }
    }

    private func scoreIncrement(for sport: Sport) -> Int {
        switch sport {
        case .basketball: return Int.random(in: 1...3)
        case .tennis: return 1
        default: return 1
        }
    }
}

@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var items: [AppNotification] = MockNotificationFactory.seed()

    var unreadCount: Int {
        items.filter { !$0.isRead }.count
    }

    func markAllRead() {
        items = items.map {
            var copy = $0
            copy.isRead = true
            return copy
        }
    }

    func markRead(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isRead = true
    }

    func push(_ notification: AppNotification) {
        items.insert(notification, at: 0)
    }
}

import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var balance: Double
    var totalWon: Double
    var totalLost: Double
    var totalBetsPlaced: Int
    var username: String
    var level: Int
    var experience: Int
    var favoriteSportRaw: String
    var createdAt: Date
    var notificationsEnabled: Bool
    var soundEnabled: Bool
    var startingBalance: Double

    var favoriteSport: Sport {
        get { Sport(rawValue: favoriteSportRaw) ?? .soccer }
        set { favoriteSportRaw = newValue.rawValue }
    }

    var netProfit: Double {
        totalWon - totalLost
    }

    var experienceProgress: Double {
        let needed = Double(level * 100)
        guard needed > 0 else { return 0 }
        return min(1, Double(experience) / needed)
    }

    var displayLevelTitle: String {
        switch level {
        case 1...2: return "Rookie"
        case 3...5: return "Regular"
        case 6...9: return "Sharp"
        case 10...14: return "Pro"
        default: return "Legend"
        }
    }

    init(
        id: UUID = UUID(),
        balance: Double = 1000.0,
        username: String = "Player1",
        level: Int = 1,
        experience: Int = 0,
        totalWon: Double = 0,
        totalLost: Double = 0,
        totalBetsPlaced: Int = 0,
        favoriteSport: Sport = .soccer,
        createdAt: Date = Date(),
        notificationsEnabled: Bool = true,
        soundEnabled: Bool = true,
        startingBalance: Double = 1000.0
    ) {
        self.id = id
        self.balance = balance
        self.username = username
        self.level = level
        self.experience = experience
        self.totalWon = totalWon
        self.totalLost = totalLost
        self.totalBetsPlaced = totalBetsPlaced
        self.favoriteSportRaw = favoriteSport.rawValue
        self.createdAt = createdAt
        self.notificationsEnabled = notificationsEnabled
        self.soundEnabled = soundEnabled
        self.startingBalance = startingBalance
    }

    func addExperience(_ points: Int) {
        experience += points
        while experience >= level * 100 {
            experience -= level * 100
            level += 1
        }
    }
}

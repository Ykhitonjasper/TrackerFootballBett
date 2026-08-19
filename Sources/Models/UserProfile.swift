import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var displayName: String
    var favoriteSportRaw: String
    var createdAt: Date
    var notificationsEnabled: Bool
    var soundEnabled: Bool

    var favoriteSport: Sport {
        get { Sport(rawValue: favoriteSportRaw) ?? .soccer }
        set { favoriteSportRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        displayName: String = "Fan",
        favoriteSport: Sport = .soccer,
        createdAt: Date = Date(),
        notificationsEnabled: Bool = true,
        soundEnabled: Bool = true
    ) {
        self.id = id
        self.displayName = displayName
        self.favoriteSportRaw = favoriteSport.rawValue
        self.createdAt = createdAt
        self.notificationsEnabled = notificationsEnabled
        self.soundEnabled = soundEnabled
    }
}

import SwiftUI
import SwiftData

@main
struct TrackerBetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .modelContainer(for: [UserProfile.self, Bet.self, Match.self])
        }
    }
}

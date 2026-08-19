import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    MatchFeedScreen()
                }
                .tabItem { Label("Matches", systemImage: "sportscourt.fill") }
                .tag(0)

                NavigationStack {
                    PicksBoardScreen()
                }
                .tabItem { Label("Predictions", systemImage: "lightbulb.fill") }
                .tag(1)

                ProfileScreen()
                    .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                    .tag(2)
            }
            .tint(AppTheme.accent)

            if !hasCompletedOnboarding {
                OnboardingScreen()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .onAppear {
            SeedService.shared.seedIfNeeded(context: modelContext)
            LiveMatchSimulator.shared.start(context: modelContext)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [UserProfile.self, Match.self, MatchPick.self], inMemory: true)
}

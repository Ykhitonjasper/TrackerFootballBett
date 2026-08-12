import SwiftUI
import SwiftData

struct OnboardingScreen: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var step = 0
    @State private var username = ""
    @State private var favoriteSport: Sport = .soccer
    @State private var appear = false

    private let steps = ["Welcome", "Profile", "Ready"]

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Capsule()
                            .fill(index <= step ? AppTheme.accent : Color.white.opacity(0.15))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                TabView(selection: $step) {
                    welcomeStep.tag(0)
                    profileStep.tag(1)
                    readyStep.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: step)

                bottomBar
                    .padding(24)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appear = true }
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(AppTheme.accent)
                .scaleEffect(appear ? 1 : 0.8)
                .opacity(appear ? 1 : 0)

            Text("TrackerFootballBett")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            Text("Track live scores, place paper bets, and climb the leaderboard — all in one demo bankroll.")
                .font(.body)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            featureRow(icon: "sportscourt.fill", title: "Multi-sport feed", subtitle: "Soccer, NBA, tennis, NHL, esports")
            featureRow(icon: "bolt.fill", title: "Live simulation", subtitle: "Scores and markets evolve in real time")
            featureRow(icon: "trophy.fill", title: "Competitive ranks", subtitle: "Weekly ladder based on your net profit")
            Spacer()
        }
    }

    private var profileStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            Text("Create your profile")
                .font(.title.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Username")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)

            TextField("At least 3 characters", text: $username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(AppTheme.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusM, style: .continuous))

            Text("Favorite sport")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(Sport.allCases) { sport in
                    Button {
                        favoriteSport = sport
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: sport.iconName)
                                .font(.title2)
                            Text(sport.rawValue)
                                .font(.caption2.weight(.semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(favoriteSport == sport ? .white : AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(favoriteSport == sport ? sport.accentColor.opacity(0.35) : AppTheme.surfaceElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusM, style: .continuous)
                                .stroke(favoriteSport == sport ? sport.accentColor : AppTheme.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusM, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var readyStep: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.accent)
            Text("You're set, \(displayName)")
                .font(.title.bold())
            Text("Starting bankroll: \(CurrencyFormatter.string(from: 1000))\nFavorite: \(favoriteSport.rawValue)")
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button("Back") {
                    withAnimation { step -= 1 }
                }
                .buttonStyle(SecondaryButtonStyle())
            }

            Button(step == steps.count - 1 ? "Start betting" : "Continue") {
                if step < steps.count - 1 {
                    if step == 1 && !Validation.username(username) { return }
                    withAnimation { step += 1 }
                } else {
                    finish()
                }
            }
            .buttonStyle(PrimaryButtonStyle(isEnabled: step != 1 || Validation.username(username)))
            .disabled(step == 1 && !Validation.username(username))
        }
    }

    private var displayName: String {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "player" : trimmed
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    private func finish() {
        let existing = (try? modelContext.fetch(FetchDescriptor<UserProfile>())) ?? []
        existing.forEach { modelContext.delete($0) }

        let profile = UserProfile(
            balance: 1000,
            username: username.trimmingCharacters(in: .whitespacesAndNewlines),
            favoriteSport: favoriteSport
        )
        modelContext.insert(profile)
        SeedService.shared.seedIfNeeded(context: modelContext)
        try? modelContext.save()

        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            hasCompletedOnboarding = true
        }
    }
}

import SwiftUI

struct HelpScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                intro
                section(
                    title: "Predictions",
                    body: "Each card is a written forecast: home, draw, or away, plus home-or-draw, away-or-draw, both to score, and over/under 2.5 goals on soccer. Confidence is 1–5. Copy the reference code if you want it on your clipboard."
                )
                section(
                    title: "Match feed",
                    body: "Browse live, upcoming, and finished fixtures across soccer, basketball, tennis, hockey, baseball, and esports. Filter by sport or status, then open any card for the scoreboard."
                )
                section(
                    title: "Match details",
                    body: "Each fixture shows teams, score, clock, venue, the prediction note when one exists, key timeline moments, and optional stats. Star a match to keep it on your watchlist."
                )
                section(
                    title: "Watchlist",
                    body: "Starred fixtures live under Profile. Use it to jump back to games you are following. Nothing is shared with other people."
                )
                section(
                    title: "On this device",
                    body: "The display name you enter on first launch stays on this iPhone. There is no server profile."
                )
                glossary
                responsible
            }
            .padding(16)
        }
        .screenBackground()
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How Match Journal works")
                .font(.title2.bold())
            Text("A local match journal for predictions, live scores, form, and a personal watchlist.")
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(16)
        .cardStyle(elevated: true)
    }

    private var glossary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Glossary")
                .font(.headline)
            glossaryRow("1 / X / 2", "Home, draw, away — the match result grid.")
            glossaryRow("Home or Draw", "Home win or a stalemate.")
            glossaryRow("Away or Draw", "Away win or a stalemate.")
            glossaryRow("Both to Score", "Whether both teams find the net.")
            glossaryRow("Over / Under 2.5", "Combined goals above or below 2.5.")
            glossaryRow("Code", "A short reference code you can copy for your own notes.")
            glossaryRow("Landed", "The final score matched the forecast.")
            glossaryRow("Missed", "The final score went the other way.")
        }
        .padding(16)
        .cardStyle()
    }

    private var responsible: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Personal notes only")
                .font(.headline)
            Text("Predictions are editorial match notes for your own research. Match Journal does not take payments or keep a server-side profile. Upcoming product updates are listed on the support site.")
                .font(.footnote)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(16)
        .cardStyle()
    }

    private func section(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardStyle()
    }

    private func glossaryRow(_ term: String, _ meaning: String) -> some View {
        HStack(alignment: .top) {
            Text(term)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 88, alignment: .leading)
            Text(meaning)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer(minLength: 0)
        }
    }
}

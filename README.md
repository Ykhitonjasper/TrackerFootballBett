# Match Journal

Local iOS match journal for predictions, live scores, and a personal watchlist.

## Stack

- SwiftUI + SwiftData, iOS 17+
- XcodeGen (`project.yml`)
- Codemagic App Store release (see `codemagic.yaml`)
- Marketing / legal / updates: Cloudflare Pages in `Site/`

## Local

```bash
brew install xcodegen
xcodegen generate
open TrackerBet.xcodeproj
```

## Site

```bash
cd Site
npx wrangler pages deploy . --project-name match-journal
```

## Codemagic

Push to `main` triggers **App Store Release**:

- Display name: `Match Journal`
- Bundle ID: `com.YvianDorel.TrackerFootballBett`
- Scheme: `TrackerBet`
- Group: `app_store_credentials`

Store listing copy: `OUTPUTS/store-listing.md`
Review notes: `OUTPUTS/review-notes.md`

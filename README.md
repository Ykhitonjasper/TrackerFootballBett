# Tracker Football Bett

iOS SwiftUI paper-betting / match tracker stub.

## Stack

- SwiftUI + SwiftData, iOS 17+
- XcodeGen (`project.yml`)
- Codemagic App Store release (see `codemagic.yaml`)

## Local

```bash
brew install xcodegen
xcodegen generate
open TrackerBet.xcodeproj
```

## Codemagic

Push to `main` triggers **App Store Release** (same credential group as [LaJugada](https://github.com/Ykhitonjasper/LaJugada)):

- Bundle ID: `com.EliasLeonelGonzalez.TrackerFootballBett`
- Scheme: `TrackerBet`
- Group: `app_store_credentials`

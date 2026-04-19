# SolanaWallet

iOS wallet for the Solana blockchain. Portfolio project.

## Environment

- Xcode 26+
- iOS 26+
- Swift 6.2

## Installation

```bash
git clone <repo-url>
cd solana-wallet
brew install swiftlint swiftformat lefthook
lefthook install
open SolanaWallet.xcworkspace
```

`lefthook install` generates `.git/hooks/pre-commit` from `lefthook.yml`. Every commit then runs SwiftFormat (auto-fix + re-stage) and SwiftLint (strict) on staged Swift files.

## Architecture

Modular SwiftPM packages siblings to the Xcode project:

- **Core** — `CoreDomain` (entities + domain), `CoreInfrastructure`, `CorePresentation` (`CoreUI`)
- **Features** — `FeatureDashboard`, `FeatureVault`, `FeatureWallet`

The `SolanaWallet` target is a thin app shell (entry point + composition root) that links the feature libraries.

## Tooling

Configs live at the project root:

- `.swiftformat` — format rules (reads `.swift-version` for language version)
- `.swiftlint.yml` — lint rules
- `lefthook.yml` — pre-commit hook

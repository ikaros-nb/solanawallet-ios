# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & test commands

Open the workspace, not the project — the workspace bundles the sibling SwiftPM packages alongside `SolanaWallet.xcodeproj`:

```bash
open SolanaWallet.xcworkspace
```

`AllTests.xctestplan` aggregates `CoreInfrastructureTests` (SPM) and `SolanaWalletIntegrationTests` (Xcode XCTest target). Both use the Swift `Testing` framework (`@Suite`, `@Test`), not XCTest.

```bash
# Build the app (workspace required so SPM packages resolve)
xcodebuild -workspace SolanaWallet.xcworkspace -scheme SolanaWallet \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# Run the full test plan
xcodebuild test -workspace SolanaWallet.xcworkspace -scheme SolanaWallet \
  -testPlan AllTests -destination 'platform=iOS Simulator,name=iPhone 17'

# Run only the SPM unit tests for CoreInfrastructure (no simulator needed)
cd CoreInfrastructure && swift test

# Run a single Swift Testing test by name
cd CoreInfrastructure && swift test --filter 'BorshCoderTests'
```

`SolanaWalletIntegrationTests` exercises real Keychain + Secure Enclave APIs; it must run on a simulator/device, not via `swift test`.

## Lint & format

```bash
lefthook install               # one-time: wires pre-commit (SwiftFormat auto-fix + SwiftLint --strict)
swiftformat .                  # manual run
swiftlint lint --strict        # manual run; CI treats warnings as errors
```

SwiftLint runs `--strict` in the pre-commit hook — any warning blocks the commit. `analyzer_rules` include `unused_declaration` and `unused_import`, which only fire under `swiftlint analyze` against a compiled build.

## Local Solana RPC (Surfpool)

`Config/Debug.xcconfig` sets `SOLANA_RPC_ENDPOINT = http://localhost:8899` (Surfpool). The `test-ledger/` directory at the repo root is its on-disk validator state — don't commit changes to it, and don't delete it without checking that nobody is mid-session.

The endpoint is injected: xcconfig → `SOLANA_RPC_ENDPOINT` → Info.plist `SolanaRpcEndpoint` key → read by `AppDependencies.solanaRpcEndpoint()`. The fallback is `http://localhost:8899` so previews and unit tests (where `Bundle.main` is the test/preview bundle) keep a usable default. Network is hardcoded to `.devnet`.

## Architecture

### Module layout

The Xcode workspace stitches together a thin app target (`SolanaWallet/`) and six sibling SwiftPM packages:

```
SolanaWallet (app shell)  ── composition root, no business logic
├── CoreDomain            ── pure value types + protocols, no Foundation deps in entities
│   ├── CoreEntities      ── Pubkey/Lamports aliases, WalletAccount, SecureSeedPhrase, etc.
│   └── CoreDomain        ── WalletReader / WalletCreator / TransactionSender / BiometricAuthenticator protocols + WalletError
├── CoreInfrastructure    ── concrete impls; depends on solana-swift; KeychainWalletStore, SecureEnclaveManager, SolanaClient, WalletProvisioner, JailbreakDetector, AppLog
├── CorePresentation      ── CoreUI library: typography, button styles, color palette, shared components
├── FeatureDashboard      ── TabView "Home"
├── FeatureVault          ── TabView "Vault"
└── FeatureWallet         ── onboarding flow (Welcome → Biometry → RecoveryPhrase)
```

Features depend on `CoreUI` and (where needed) `CoreDomain`. They **do not** depend on `CoreInfrastructure` — concrete services are injected through SwiftUI `@Environment` values declared in `FeatureWallet/WalletDependencies.swift`. The app shell is the only place that knows about both sides.

### App bootstrap & navigation

`SolanaWalletApp.init()` calls `AppDependencies.make()` exactly once (fatal-errors on failure — wallet security stack must initialize). `RootView` reads `AppState.isOnboarded` to choose between `WelcomeAssembly.make()` (no wallet yet) and `MainTabView` (post-onboarding). `AppState.rehydrate(from:)` reads the public key from Keychain on launch to set `activeWallet`.

Each feature exposes a public `*Assembly.make()` entry point that owns its own `NavigationStack` + `WalletNavigator` (a thin `NavigationPath` wrapper) and injects flow-scoped state (e.g. `OnboardingSession`) via `.environment(...)`. Routes are `Hashable` enums (`WelcomeRoute`, `BiometryRoute`, `RecoveryPhraseRoute`) — never put secrets like `SecureSeedPhrase` in a route, because `NavigationPath` may be persisted via state restoration. `OnboardingSession` holds the live phrase instead.

### Wallet security model

Two Keychain items under the same service:

- `solana-pubkey` — plaintext, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`. No prompt on read.
- `solana-keypair` — sealed by `SecureEnclaveManager` (AES via a Secure Enclave-protected key), access-controlled with `[.biometryCurrentSet, .or, .devicePasscode]`. Read triggers Face ID / passcode prompt.

`KeychainWalletStore.saveKeypair` is **non-idempotent** — it throws `keypairAlreadyExists` rather than overwriting an active wallet. Call `reset()` first. `WalletProvisioner.persist` saves the keypair *before* the pubkey so a failure leaves the existing pubkey untouched.

`withSigningSession(reason:_:)` is the only way to access the decrypted secret. The plaintext is zeroed via `defer` when the closure returns. Callers must not let the bytes escape (capture, return value, async hop).

Re-enrolling biometry after `saveKeypair` invalidates the item; only the device passcode fallback remains usable.

### Swift concurrency posture

- Swift 6.2 with strict concurrency complete, `MainActor` as default actor isolation (set in `Config/Base.xcconfig` for the app target and via `.defaultIsolation(MainActor.self)` in each UI-facing SPM package).
- `CoreInfrastructure` does **not** opt into default `MainActor` isolation. `SolanaClient` and `WalletProvisioner` are `actor`s; `KeychainWalletStore` and `SecureEnclaveManager` are `Sendable` structs.
- All SPM packages have `treatAllWarnings(as: .error)` — deprecation warnings excepted. A new warning will fail the build.
- `solana-swift` is imported with `@preconcurrency` where it crosses into our isolation domain (it predates strict concurrency).

### RPC caching contract

`SolanaClient` caches `getBalance` and `getTokenAccountsByOwner` results per `Pubkey`. On RPC failure, if a cached value exists it is wrapped and thrown as `WalletError.staleCache(_, underlying:)` / `WalletError.staleTokenCache(_, underlying:)` — callers can fall back to the stale value while showing the underlying error. Callers that need fresh-only data must inspect the error variant.

## Conventions

- Logging goes through `AppLog.logger(for: "Category")` (subsystem: `com.ikaros.SolanaWallet.coreinfrastructure`). Use `privacy: .public` only for non-sensitive fields.
- Debug-only logging of solana-swift internals is wired through `SolanaSwiftLoggerImpl` and `LoggingNetworkManager`, behind `#if DEBUG` in `AppDependencies`.
- Identifier naming: `Pubkey` is a base58 `String` alias, `Lamports` is `UInt64`, `TransactionSignature` is `String`. Don't reintroduce raw types in domain code.
- File header comments (auto-generated by Xcode) are preserved — SwiftFormat is configured with `--header ignore`.

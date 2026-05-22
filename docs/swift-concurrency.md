# Swift concurrency posture

> Read this when adding a new SPM target, debugging a `Sendable` / isolation warning, or wiring a `CoreInfrastructure` type into UI code.

## Defaults

- Swift 6.2, strict concurrency complete across every target.
- `MainActor` is the default actor isolation for UI-facing code:
  - **App target**: `Config/Base.xcconfig` sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
  - **SPM packages** (`CorePresentation`, `FeatureDashboard`, `FeatureVault`, `FeatureWallet`): each `Package.swift` sets `.defaultIsolation(MainActor.self)` in `swiftSettings`.
- `treatAllWarnings(as: .error)` on every SPM package (deprecations excepted). A new warning fails the build.

## Exception: `CoreDomain` and `CoreInfrastructure`

These two packages do **not** opt into default `MainActor`. Domain types must be usable from any isolation context, and infrastructure types must do off-main work.

| Type | Kind | Why |
|---|---|---|
| `SolanaClient` | `actor` | serializes RPC + cache access; called from any context |
| `WalletProvisioner` | `actor` | serializes wallet creation; uses BIP39 derivation off main |
| `KeychainWalletStore` | `Sendable struct` | stateless wrapper around Keychain syscalls |
| `SecureEnclaveManager` | `Sendable struct` | stateless wrapper around CryptoKit + Keychain |
| `TokenRepository` (implementations) | `Sendable` | injected into `SolanaClient.init` |

Domain protocols (`WalletReader`, `TransactionSender`, `VaultTransactor`, …) declare `async throws` methods so concrete implementations can be actors or main-isolated stubs.

## `solana-swift` boundary

`solana-swift` predates strict concurrency. It is imported with `@preconcurrency` at every site that crosses into our isolation domain. To find boundary sites:

```
grep -rn "@preconcurrency import SolanaSwift" CoreInfrastructure/
```

If you add a file that uses solana-swift types and the build complains about `Sendable`, add `@preconcurrency import SolanaSwift`. Do **not** weaken our own `Sendable` conformances to silence it.

## Signing closure isolation

`KeychainWalletStore.withSigningSession<T: Sendable>(reason:_:)` takes `@Sendable (Data) throws -> T`. The closure runs on whatever context called the method — typically inside `SolanaClient` (an `actor`). Two consequences:

- `T` must be `Sendable`. In practice `SolanaClient.signTransaction` returns a `String` (the base64-encoded transaction), which is.
- The plaintext `Data` argument is **not** safe to send. The `@Sendable` constraint is on the closure, not on its parameter — Swift's region-based isolation lets the actor pass non-Sendable state into a Sendable closure as long as the state does not escape. This is exactly the property that lets `defer { keypair.resetBytes(...) }` work. Do not capture the `Data` outside the closure.

## When you hit a concurrency error

1. If the type is yours, ask whether it should be `Sendable`, `actor`, or `@MainActor`-isolated — pick one and stick to it. Don't add `@unchecked Sendable` to silence warnings without a reason.
2. If the type is from solana-swift, add `@preconcurrency import SolanaSwift` to the file.
3. If you need to hop to the main actor from `CoreInfrastructure`, use `await MainActor.run { ... }` — but most of the time that hop belongs in the feature module's view model, not in infrastructure code.

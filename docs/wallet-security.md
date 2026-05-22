# Wallet security model

> Read this when touching anything in `CoreInfrastructure/Sources/CoreInfrastructure/Security/` or the wallet-creation / signing paths in `Wallet/WalletProvisioner.swift`.

## Keychain layout

Three items live under one Keychain service (default `com.ikaros.SolanaWallet.wallet`):

| Account | Contents | Accessibility | Prompt on read |
|---|---|---|---|
| `solana-pubkey` | base58 public key, plaintext | `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` | no |
| `solana-keypair` | keypair sealed by `SecureEnclaveManager` | `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly` + `[.biometryCurrentSet, .or, .devicePasscode]` | yes (Face ID / Touch ID / passcode) |
| `solana-biometry-state` | hash of currently enrolled biometry set | `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` | no |

A fourth Keychain item, **`se-encryption-key`** under a separate service (`com.ikaros.SolanaWallet.secure-enclave`), holds the `dataRepresentation` of the Secure Enclave P-256 key handle used to seal `solana-keypair`. The actual private scalar never leaves the Secure Enclave.

## `KeychainWalletStore` contract

- `savePublicKey(_:)` / `saveBiometryState(_:)` are **idempotent** (`SecItemAdd` → fallback `SecItemUpdate`).
- `saveKeypair(_:)` is **non-idempotent**: returns `.keypairAlreadyExists` on `errSecDuplicateItem`. Call `reset()` first if you intend to overwrite. This is the safety net against a buggy flow wiping an active wallet.
- `reset()` wipes all three wallet Keychain items *and* destroys the Secure Enclave encryption key (`secureEnclave.reset()`). After it returns, no prior keypair ciphertext is decryptable on this device. Each step is independently idempotent — partial failure is safe to retry.

## `withSigningSession(reason:_:)`

This is the **only** path to the decrypted keypair.

```
func withSigningSession<T: Sendable>(
    reason: String,
    _ block: @Sendable (Data) throws -> T
) throws -> T
```

Sequence:
1. `LAContext` with `localizedReason: reason` — drives the system prompt copy.
2. `SecItemCopyMatching` with `kSecUseAuthenticationContext` — Apple triggers biometry / passcode.
3. `secureEnclave.decrypt(blob)` produces plaintext `keypair: Data`.
4. `defer { keypair.resetBytes(in: 0..<keypair.count) }`.
5. `try block(keypair)`.

Status codes map to `KeychainWalletStore.Failure`:

| `OSStatus` | Failure |
|---|---|
| `errSecSuccess` | (returns) |
| `errSecUserCanceled` | `.userCancelled` |
| `errSecItemNotFound` | `.walletNotFound` |
| `errSecAuthFailed` | `.biometryFailed` |
| other | `.keychainError(status)` |

**Hard rule for callers**: do not let the plaintext bytes escape the closure — no capturing in a returned value, no async hop, no stashing in an `@escaping` callback. The `defer` zero-clear is moot if the bytes leak. The only legitimate use of the plaintext today is constructing a solana-swift `KeyPair` inside `SolanaClient.signTransaction` and discarding it after `tx.sign(...)` and `tx.serialize().base64EncodedString()`.

## `SecureEnclaveManager`

ECIES-style hybrid encryption (`Security/SecureEnclaveManager.swift`):

1. Generate ephemeral P-256 keypair in process memory.
2. ECDH between ephemeral private key and Secure-Enclave-bound public key.
3. HKDF-SHA256 with versioned `sharedInfo` (`"SolanaWallet.se-encryption.v1"`) → 32-byte AES key.
4. AES-GCM seal (random nonce per call).
5. Blob layout: `ephemeralPublicKey(64) ‖ nonce(12) ‖ ciphertext ‖ tag(16)` — minimum 92 bytes.

Decrypt reverses the envelope; the ECDH itself runs *inside* the enclave (private scalar never reaches process memory). AES-GCM's tag authenticates the whole blob — a single flipped bit fails closed with `corruptedCiphertext` / open failure, not partial plaintext.

Note: this is **not** forward secrecy — the Secure Enclave key is long-term, so its compromise would expose every past ciphertext. The ephemeral only guarantees nonce/key uniqueness per call.

The manager is agnostic to payload content (no knowledge of Solana keypair structure — see ADR-002 D9). Callers serialize their own data.

## Biometry re-enrollment

`[.biometryCurrentSet, .or, .devicePasscode]` on `solana-keypair` means: re-enrolling Face ID / Touch ID after `saveKeypair` invalidates the biometry path — only the device passcode fallback remains. The `solana-biometry-state` item is a hash captured at `WalletProvisioner.persist` time; it's compared on launch so the UI can warn the user when re-enrollment was detected. `clearBiometryState()` is called when biometry is removed from the device entirely, so the next launch with re-enrolled biometry captures a fresh baseline.

## `WalletProvisioner.persist` order

In `Wallet/WalletProvisioner.swift`:

1. `keychain.saveKeypair(...)` — first, because it can throw `.keypairAlreadyExists`.
2. `keychain.savePublicKey(...)` — second, only if (1) succeeded.
3. Biometry baseline capture — best-effort, errors logged but not thrown.

Failing in this order means a partial-write leaves either nothing persisted (keypair save threw) or a sealed keypair with no pubkey (pubkey save threw). It never leaves a stale pubkey pointing at the wrong sealed keypair. `AppState.rehydrate(from:)` reads the pubkey on launch — if it sees one, the keypair is also present.

## Auxiliary security utilities

- `Security/JailbreakDetector.swift` — runs heuristic checks at launch.
- `Security/FilesystemProbe.swift` — used by the detector to probe sandbox boundaries.
- `Security/LocalAuthenticationBiometricAuthenticator.swift` — `LAContext` wrapper conforming to the domain `BiometricAuthenticator` protocol; used for low-stakes biometry challenges that don't unlock the keypair.
- `Security/URLOpener.swift` — system URL opening with policy gating.

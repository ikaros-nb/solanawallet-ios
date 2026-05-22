# SolanaClient & RPC flows

> Read this when touching anything in `CoreInfrastructure/Sources/CoreInfrastructure/Network/`, debugging an RPC error path, or wiring a new on-chain interaction.

## Shape

`SolanaClient` is a single `actor` (`Network/SolanaClient.swift`) that owns three collaborators and four pubkey-keyed caches:

| Collaborator | Type | Source |
|---|---|---|
| `rpc` | `SolanaAPIClient` (solana-swift) | injected by `AppDependencies` |
| `keychain` | `KeychainWalletStore` | the only path to the signing secret |
| `tokenRepository` | `TokenRepository` | off-chain SPL metadata (name/symbol) |

All RPC enters and exits through this actor. Per-protocol concerns are split across extension files (`SolanaClient+*.swift`), each conforming to one `CoreDomain` protocol:

| Extension file | Conforms to | Public surface |
|---|---|---|
| `+WalletReader.swift` | `WalletReader` | `fetchBalance(for:)`, `fetchTokenAccounts(for:)` |
| `Wallet/+TokenBalanceReader.swift` | `TokenBalanceReader` | `fetchTokenBalance(for:mint:)` |
| `Wallet/+TransactionSender.swift` | `TransactionSender` | `sendSOL(...)`, `sendSPL(...)` |
| `Vault/+VaultBalanceReader.swift` | `VaultBalanceReader` | `fetchVaultBalance(for:)` |
| `Vault/+VaultStateReader.swift` | `VaultStateReader` | `fetchVaultExists(for:)` |
| `Vault/+VaultHistoryReader.swift` | `VaultHistoryReader` | `fetchVaultTransactions(for:limit:)` |
| `Vault/+VaultTransactor.swift` | `VaultTransactor` | `initializeVault`, `depositVault`, `withdrawVault` |
| `+TransactionOrchestrator.swift` | (internal) | `submitInstruction(s)`, `signTransaction`, `confirmSignature` |

## Caching contract

```
balanceCache:      [Pubkey: Lamports]
tokensCache:       [Pubkey: [SPLTokenAccount]]
vaultBalanceCache: [Pubkey: Decimal]
vaultHistoryCache: [Pubkey: [VaultTransaction]]
```

- Each successful read writes the value at `cache[owner]`. Each successful send removes the affected entries.
- `invalidateAllCaches(for:)` is the public wipe. `invalidateVaultCaches(for:)` (private) is called after vault init/deposit/withdraw.
- On RPC failure, if a cached value exists, `mapToStaleCacheError` wraps the underlying `WalletError` as `.staleCache`, `.staleTokenCache`, `.staleVaultCache`, or `.staleVaultHistoryCache`. Callers that need fresh-only data must inspect the error variant.
- `fetchVaultBalance` treats "account not found" as a hard zero (caches `0`), not as a stale-cache miss — newly-created wallets have no PDA yet.

## Transaction orchestrator

`submitInstructions` (`+TransactionOrchestrator.swift`) is the single send pipeline:

```
1. PublicKey(string: owner)                            // throws .vaultError on decode failure
2. rpc.getLatestBlockhash(commitment: .default)        // .default == .confirmed
3. signTransaction(...)                                // wraps keychain.withSigningSession
     ├─ user is prompted (Face ID / passcode)
     ├─ KeyPair(phrase: [], publicKey, secretKey)
     ├─ Transaction(instructions, recentBlockhash, feePayer)
     ├─ tx.sign(signers: [signer])
     └─ tx.serialize().base64EncodedString()
4. rpc.sendTransaction(transaction:, configs: base64 + .default)
5. confirmSignature(signature)
     ├─ rpc.observeSignatureStatus(signature:, timeout: 60, delay: 2)
     ├─ return on .confirmed or .finalized
     └─ throw WalletError.transactionExpired on timeout
6. return TransactionSignature
```

Signing-session errors collapse to `WalletError.signingFailed` (cancellation, biometry failure, anything unexpected). `WalletError` thrown from inside the closure is rethrown verbatim. **There is no automatic retry.** UI re-tap is the retry path.

## Send-SOL flow

`DashboardViewModel.send(asset: .sol)` → `transactionSender.sendSOL(from:to:amount:)`:

```
sendSOL(from owner, to recipient, amount)
  ├─ decode owner, recipient via PublicKey(string:)
  ├─ guard owner != recipient                            → .sendToSelf
  ├─ recipientWalletExists(recipient)
  │     ├─ rpc.getAccountInfo
  │     ├─ if owner != SystemProgram.id                  → .recipientNotWallet
  │     └─ returns false if account-not-found
  ├─ if !recipientExists:
  │     └─ ensureAboveRentMinimum(amount)                → .belowRentExemption
  ├─ SystemProgram.transferInstruction(from, to, lamports)
  ├─ submitInstruction(...)                              // orchestrator
  └─ balanceCache.removeValue(forKey: owner)
```

## Send-SPL flow

`DashboardViewModel.send(asset: .spl(token))` → `transactionSender.sendSPL(...)`:

```
sendSPL(from owner, token: SPLTokenRef, to recipient, amount)
  ├─ decode owner, recipient, mint, programId
  ├─ guard owner != recipient                            → .sendToSelf
  ├─ assertRecipientIsWallet(recipient)                  → .recipientNotWallet
  │     (silent if recipient does not yet exist — ATA-create handles it)
  ├─ sourceATA = associatedTokenAddress(owner, mint, programId)
  ├─ destinationATA = associatedTokenAddress(recipient, mint, programId)
  ├─ instructions = [
  │     AssociatedTokenProgram.createIdempotentInstruction(...),
  │     buildTransferChecked(accounts, amount, decimals)
  │   ]
  │     // buildTransferChecked dispatches to Token2022Program if
  │     // programId matches, else TokenProgram. Both use *TransferChecked*
  │     // so decimals mismatch fails on-chain rather than silently moving
  │     // the wrong amount.
  ├─ submitInstructions(...)                             // orchestrator
  ├─ tokensCache.removeValue(forKey: owner)
  └─ balanceCache.removeValue(forKey: owner)             // SPL transfer burns fee SOL
```

## Token account fetch

`fetchTokenAccounts(for:)` does parallel dual-program reads:

```
async let classicRaw = rpc.getTokenAccountsByOwner(programId: TokenProgram.id, ...)
async let token2022Raw = rpc.getTokenAccountsByOwner(programId: Token2022Program.id, ...)
// after both resolve:
uniqueMints = Set(classic + token2022)
async let metadata = tokenRepository.get(addresses: uniqueMints)        // off-chain
async let mintDatas = rpc.getMultipleMintDatas(uniqueMints, TokenMintState.self)
// TokenMintState decodes the 82-byte mint prefix shared by SPL + Token-2022,
// so a single batch covers both programs.
```

`VLT` mint gets hard-coded `name`/`symbol` from `CoreEntities/VLT.swift` instead of metadata — keep this special case if `VLT.mint` ever changes.

## Vault flows

PDA derivation lives in `Network/Vault/VaultProgram+ABI.swift`:

- `VaultProgram.statePDA(for owner)` — vault state account
- `VaultProgram.tokenAccountPDA(for owner)` — VLT balance account
- `initializeInstruction(owner:)`, `depositInstruction(owner:amount:)`, `withdrawInstruction(owner:amount:)`

| Method | What it does | Cache effect |
|---|---|---|
| `fetchVaultExists(for:)` | `getMultipleAccounts` on statePDA, checks owner == `VaultProgram.id` | none |
| `fetchVaultBalance(for:)` | `getTokenAccountBalance` on tokenAccountPDA, decodes via `VaultAmount.decode` | writes `vaultBalanceCache`; 0 cached on account-not-found |
| `fetchVaultTransactions(for:limit:)` | `getSignaturesForAddress` on statePDA + parallel `getTransaction` (max 4 concurrent), decodes via `VaultTransactionDecoder` | writes `vaultHistoryCache` |
| `initializeVault`, `depositVault`, `withdrawVault` | build instruction → `submitInstruction` | `invalidateVaultCaches(owner)` |

### Why `fetchVaultExists` uses `getMultipleAccounts`

`getAccountInfo` in solana-swift hardcodes its request config and never passes a commitment, so the RPC defaults to `finalized`. The rest of our reads use `confirmed` via `SolanaCommitment.default`. A vault we just initialized (orchestrator returns at `confirmed`) would be invisible to `getAccountInfo` for ~13s. `getMultipleAccounts` takes the commitment explicitly, so it sees the freshly-initialized vault.

## Error mapping

`Network/WalletErrorMapping.swift` is the single funnel from solana-swift / Foundation errors to `WalletError`. Everywhere `SolanaClient` catches an error, it calls `mapToWalletError(_:)` or `mapToStaleCacheError(_:cached:wrap:)`.

| Source | `WalletError` |
|---|---|
| `NSURLErrorCannotConnectToHost` | `.nodeUnreachable` |
| `NSURLErrorNotConnectedToInternet`, `NSURLErrorTimedOut` | `.networkUnavailable` |
| `APIClientError.blockhashNotFound` | `.transactionExpired` |
| `APIClientError.transactionSimulationError` with "insufficient lamports" / "insufficient funds" log | `.insufficientSOL` |
| `APIClientError.transactionSimulationError` (other) | `.vaultError(-32002, lastLog)` |
| `APIClientError.couldNotRetrieveAccountInfo` | `.vaultError(0, "account not found")` |
| RPC response code `-32002` with "blockhash" in message | `.transactionExpired` |
| RPC response code `-32003` | `.signingFailed` |
| RPC response code `-32005` | `.nodeUnreachable` |
| `TransactionConfirmationError.unconfirmed` | `.transactionExpired` |
| anything else | `.unknown(underlying:)` |

`mapToStaleCacheError(_:cached:wrap:)`: maps the underlying error, then if `cached` is non-nil wraps via the `wrap` closure (`.staleCache`, `.staleTokenCache`, `.staleVaultCache`, `.staleVaultHistoryCache`). Otherwise returns the mapped error as-is.

## Debug logging

DEBUG-only and wired in `SolanaWallet/AppDependencies.swift`:

- `Debug/LoggingNetworkManager.swift` — wraps URLSession, logs JSON-RPC method/URL, body preview (2KB cap), response latency, errors. Subsystem `SolanaSwift.Network`.
- `Debug/SolanaSwiftLoggerImpl.swift` — bridges solana-swift's internal `SolanaSwiftLogger` to `AppLog`. Subsystem `SolanaSwift`.

In Release both are skipped — no logging overhead, no body capture.

## solana-swift surface

`solana-swift` is imported with `@preconcurrency` at every site that crosses into our isolation domain (search `@preconcurrency import SolanaSwift`). Types that leak across the boundary into our infrastructure code: `SolanaAPIClient`, `PublicKey`, `Transaction`, `TransactionInstruction`, `KeyPair`, `SystemProgram`, `TokenProgram`, `Token2022Program`, `AssociatedTokenProgram`, `BufferInfo`, `APIClientError`, `ResponseError`, `RequestConfiguration`, `Commitment` (aliased to our `SolanaCommitment`).

These types do **not** leak into `CoreDomain` — the domain only sees `Pubkey` (`String`), `Lamports` (`UInt64`), `TransactionSignature` (`String`), and domain entities like `SPLTokenAccount` / `VaultTransaction`.

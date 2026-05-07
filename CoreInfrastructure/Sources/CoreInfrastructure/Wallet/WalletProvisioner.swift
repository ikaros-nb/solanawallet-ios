//
//  WalletProvisioner.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 01/05/2026.
//

import CoreDomain
import CoreEntities
import Foundation
import os
import SolanaSwift

public actor WalletProvisioner: WalletCreator {
    private static let logger = AppLog.logger(for: "WalletProvisioner")

    private static let validMnemonicWordCounts: Set<Int> = [12, 15, 18, 21, 24]

    private let keychain: KeychainWalletStore

    public init(keychain: KeychainWalletStore) {
        self.keychain = keychain
    }

    // `nonisolated` to satisfy the sync protocol requirement; safe because
    // `Mnemonic(strength:)` only uses `SecRandomCopyBytes` and an immutable
    // wordlist, touching no shared state.
    public nonisolated func generateSeedPhrase() -> SecureSeedPhrase {
        let mnemonic = Mnemonic(strength: 128)
        return SecureSeedPhrase(words: mnemonic.phrase)
    }

    public func createWallet(seedPhrase: SecureSeedPhrase) async throws -> WalletAccount {
        guard let words = seedPhrase.read() else {
            throw WalletError.seedPhraseUnavailable
        }
        let mnemonic: Mnemonic
        do {
            mnemonic = try Mnemonic(phrase: words)
        } catch {
            throw WalletError.invalidSeedPhrase
        }

        let keyPair = try await KeyPair(
            mnemonic: mnemonic,
            network: .devnet, // deprecated and ignored
            derivablePath: .default
        )
        try persist(keyPair)
        return WalletAccount(pubkey: keyPair.publicKey.base58EncodedString)
    }

    public func importWallet(seedPhrase: String) async throws -> WalletAccount {
        let words = seedPhrase
            .split(whereSeparator: \.isWhitespace)
            .map { String($0).lowercased() }
        guard Self.validMnemonicWordCounts.contains(words.count) else {
            throw WalletError.invalidSeedPhrase
        }
        let mnemonic: Mnemonic
        do {
            mnemonic = try Mnemonic(phrase: words)
        } catch {
            throw WalletError.invalidSeedPhrase
        }
        let keyPair: KeyPair
        do {
            keyPair = try await KeyPair(
                mnemonic: mnemonic,
                network: .devnet, // deprecated and ignored
                derivablePath: .default
            )
        } catch {
            // Mnemonic(phrase:) has already validated BIP39 ; any error here is
            // a derivation failure unrelated to the user input. Log to preserve
            // the underlying cause, surface a generic invalidSeedPhrase.
            Self.logger.error("KeyPair derivation failed: \(error, privacy: .public)")
            throw WalletError.invalidSeedPhrase
        }
        try persist(keyPair)
        return WalletAccount(pubkey: keyPair.publicKey.base58EncodedString)
    }

    private func persist(_ keyPair: KeyPair) throws {
        var secret = keyPair.secretKey
        defer { secret.resetBytes(in: 0..<secret.count) }
        // saveKeypair is non-idempotent (throws if present); savePublicKey overwrites.
        // Run the throwing one first so a failure leaves the existing pubkey untouched.
        do {
            try keychain.saveKeypair(secret)
        } catch KeychainWalletStore.Failure.keypairAlreadyExists {
            throw WalletError.walletAlreadyExists
        }
        try keychain.savePublicKey(keyPair.publicKey.data)
    }
}

//
//  WalletProvisioner.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 01/05/2026.
//

import CoreDomain
import CoreEntities
import Foundation
@preconcurrency import SolanaSwift

public actor WalletProvisioner: WalletCreator {
    private let keychain: KeychainWalletStore

    init(keychain: KeychainWalletStore) {
        self.keychain = keychain
    }

    public func createWallet() async throws -> WalletCreationResult {
        let mnemonic = Mnemonic(strength: 128)
        let keyPair = try await KeyPair(
            mnemonic: mnemonic,
            network: .devnet,
            derivablePath: .default
        )
        try persist(keyPair)
        return WalletCreationResult(
            account: WalletAccount(pubkey: keyPair.publicKey.base58EncodedString),
            seedPhrase: keyPair.phrase.joined(separator: " ")
        )
    }

    public func importWallet(seedPhrase: String) async throws -> WalletAccount {
        let words = seedPhrase
            .split(whereSeparator: \.isWhitespace)
            .map { String($0).lowercased() }
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
                network: .devnet,
                derivablePath: .default
            )
        } catch {
            throw WalletError.invalidSeedPhrase
        }
        try persist(keyPair)
        return WalletAccount(pubkey: keyPair.publicKey.base58EncodedString)
    }

    private func persist(_ keyPair: KeyPair) throws {
        var secret = keyPair.secretKey
        defer { secret.resetBytes(in: 0..<secret.count) }
        try keychain.savePublicKey(keyPair.publicKey.data)
        try keychain.saveKeypair(secret)
    }
}

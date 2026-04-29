//
//  SolanaClient.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 29/04/2026.
//

import CoreDomain
import CoreEntities
import SolanaSwift

actor SolanaClient {
    private let rpc: SolanaAPIClient
    private let keychain: KeychainWalletStore
    private var balanceCache: [Pubkey: Lamports] = [:]
    private var tokensCache: [Pubkey: [SPLTokenAccount]] = [:]

    init(rpc: SolanaAPIClient, keychain: KeychainWalletStore) {
        self.rpc = rpc
        self.keychain = keychain
    }

    func invalidateCache() {
        balanceCache.removeAll()
        tokensCache.removeAll()
    }
}

extension SolanaClient: WalletReader {
    func fetchBalance(for owner: Pubkey) async throws -> Lamports {
        throw WalletError.unknown(underlying: "not implemented (S19)")
    }

    func fetchTokenAccounts(for owner: Pubkey) async throws -> [SPLTokenAccount] {
        throw WalletError.unknown(underlying: "not implemented (S19)")
    }
}

extension SolanaClient: TransactionSender {
    func sendSOL(
        to recipient: Pubkey,
        amount: Lamports
    ) async throws -> TransactionSignature {
        throw WalletError.unknown(underlying: "not implemented (S20)")
    }

    func sendSPL(
        mint: Pubkey,
        to recipient: Pubkey,
        amount: UInt64
    ) async throws -> TransactionSignature {
        throw WalletError.unknown(underlying: "not implemented (S20)")
    }
}

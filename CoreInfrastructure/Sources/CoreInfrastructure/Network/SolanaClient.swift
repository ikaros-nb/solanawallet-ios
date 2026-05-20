//
//  SolanaClient.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 29/04/2026.
//

import CoreDomain
import CoreEntities
import Foundation
@preconcurrency import SolanaSwift

public actor SolanaClient {
    let rpc: SolanaAPIClient
    let keychain: KeychainWalletStore
    let tokenRepository: TokenRepository

    var balanceCache: [Pubkey: Lamports] = [:]
    var tokensCache: [Pubkey: [SPLTokenAccount]] = [:]
    var vaultBalanceCache: [Pubkey: Decimal] = [:]
    var vaultHistoryCache: [Pubkey: [VaultTransaction]] = [:]

    public init(
        rpc: SolanaAPIClient,
        keychain: KeychainWalletStore,
        tokenRepository: TokenRepository
    ) {
        self.rpc = rpc
        self.keychain = keychain
        self.tokenRepository = tokenRepository
    }

    func invalidateVaultCaches(for owner: Pubkey) {
        tokensCache.removeValue(forKey: owner)
        vaultBalanceCache.removeValue(forKey: owner)
        vaultHistoryCache.removeValue(forKey: owner)
    }

    public func invalidateAllCaches(for owner: Pubkey) {
        balanceCache.removeValue(forKey: owner)
        invalidateVaultCaches(for: owner)
    }
}

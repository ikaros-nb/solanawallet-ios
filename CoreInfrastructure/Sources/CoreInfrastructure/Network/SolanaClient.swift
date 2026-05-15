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
    let rpcEndpoint: URL
    let keychain: KeychainWalletStore
    let tokenRepository: TokenRepository
    let coder: BorshCoder

    var balanceCache: [Pubkey: Lamports] = [:]
    var tokensCache: [Pubkey: [SPLTokenAccount]] = [:]
    var vaultBalanceCache: [Pubkey: Decimal] = [:]
    var vaultHistoryCache: [Pubkey: [VaultTransaction]] = [:]

    public init(
        rpc: SolanaAPIClient,
        rpcEndpoint: URL,
        keychain: KeychainWalletStore,
        tokenRepository: TokenRepository,
        coder: BorshCoder = BorshCoder()
    ) {
        self.rpc = rpc
        self.rpcEndpoint = rpcEndpoint
        self.keychain = keychain
        self.tokenRepository = tokenRepository
        self.coder = coder
    }

    func invalidateCache() {
        balanceCache.removeAll()
        tokensCache.removeAll()
        vaultBalanceCache.removeAll()
        vaultHistoryCache.removeAll()
    }

    func invalidateVaultCaches(for owner: Pubkey) {
        tokensCache.removeValue(forKey: owner)
        vaultBalanceCache.removeValue(forKey: owner)
        vaultHistoryCache.removeValue(forKey: owner)
    }
}

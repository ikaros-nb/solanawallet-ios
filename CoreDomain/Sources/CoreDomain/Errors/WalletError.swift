//
//  WalletError.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 29/04/2026.
//

import CoreEntities
import Foundation

public enum WalletError: Error, Equatable, Sendable {
    case networkUnavailable
    case nodeUnreachable
    case transactionExpired
    case insufficientSOL
    case insufficientTokens
    case invalidSeedPhrase
    case seedPhraseUnavailable
    case walletAlreadyExists
    case vaultError(code: Int, message: String)
    case signingFailed
    case unknown(underlying: String)
    indirect case staleCache(Lamports, underlying: WalletError)
    indirect case staleTokenCache([SPLTokenAccount], underlying: WalletError)
    indirect case staleVaultCache(Decimal, underlying: WalletError)
}

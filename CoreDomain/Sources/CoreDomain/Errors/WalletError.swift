//
//  WalletError.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 29/04/2026.
//

public enum WalletError: Error, Equatable, Sendable {
    case networkUnavailable
    case nodeUnreachable
    case transactionExpired
    case insufficientSOL
    case insufficientTokens
    case vaultError(code: Int, message: String)
    case signingFailed
    case unknown(underlying: String)
}

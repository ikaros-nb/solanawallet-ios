//
//  SolanaClient+TransactionSender.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 15/05/2026.
//

import CoreDomain
import CoreEntities

extension SolanaClient: TransactionSender {
    public func sendSOL(
        to recipient: Pubkey,
        amount: Lamports
    ) async throws -> TransactionSignature {
        throw WalletError.unknown(underlying: "not implemented (S20)")
    }

    public func sendSPL(
        mint: Pubkey,
        to recipient: Pubkey,
        amount: UInt64
    ) async throws -> TransactionSignature {
        throw WalletError.unknown(underlying: "not implemented (S20)")
    }
}

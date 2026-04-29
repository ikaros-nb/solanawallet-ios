//
//  TransactionSender.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 29/04/2026.
//

public protocol TransactionSender: Sendable {
    func sendSOL(to recipient: Pubkey, amount: Lamports) async throws -> TransactionSignature
    func sendSPL(mint: Pubkey, to recipient: Pubkey, amount: UInt64) async throws -> TransactionSignature
}

//
//  TransactionSender.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 29/04/2026.
//

public protocol TransactionSender: Sendable {
    func sendSOL(to recipient: PublicKey, amount: Lamports) async throws -> TransactionSignature
    func sendSPL(mint: PublicKey, to recipient: PublicKey, amount: UInt64) async throws -> TransactionSignature
}

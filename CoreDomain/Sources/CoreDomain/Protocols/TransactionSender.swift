//
//  TransactionSender.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 29/04/2026.
//

import CoreEntities

public protocol TransactionSender: Sendable {
    func sendSOL(from owner: Pubkey, to recipient: Pubkey, amount: Lamports) async throws -> TransactionSignature
    func sendSPL(
        from owner: Pubkey,
        token: SPLTokenRef,
        to recipient: Pubkey,
        amount: UInt64
    ) async throws -> TransactionSignature
}

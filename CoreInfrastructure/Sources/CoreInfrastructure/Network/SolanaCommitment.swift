//
//  SolanaCommitment.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 18/05/2026.
//

@preconcurrency import SolanaSwift

enum SolanaCommitment {
    /// Default commitment level applied to every Solana RPC call.
    /// `"confirmed"` = a supermajority of the cluster has voted on the slot:
    /// balances become usable ~400ms after submission and won't show
    /// pre-vote (`"processed"`) state that could later roll back.
    static let `default`: Commitment = "confirmed"
}

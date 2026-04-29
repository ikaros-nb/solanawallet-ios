//
//  Aliases.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 29/04/2026.
//

/// Base58-encoded Solana public key (32 bytes encoded, ~44 chars).
public typealias Pubkey = String

/// Solana lamport (1 SOL = 1_000_000_000 lamports).
public typealias Lamports = UInt64

public typealias TransactionSignature = String

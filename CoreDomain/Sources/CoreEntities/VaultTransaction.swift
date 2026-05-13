//
//  VaultTransaction.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 13/05/2026.
//

import Foundation

public struct VaultTransaction: Sendable, Equatable, Identifiable {
    public enum Kind: Sendable, Equatable {
        case deposit
        case withdraw
    }

    public let signature: TransactionSignature
    public let kind: Kind
    public let amount: Decimal
    public let timestamp: Date
    public let slot: UInt64

    public var id: TransactionSignature {
        signature
    }

    public init(
        signature: TransactionSignature,
        kind: Kind,
        amount: Decimal,
        timestamp: Date,
        slot: UInt64
    ) {
        self.signature = signature
        self.kind = kind
        self.amount = amount
        self.timestamp = timestamp
        self.slot = slot
    }
}

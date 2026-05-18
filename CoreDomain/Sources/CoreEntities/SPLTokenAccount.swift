//
//  SPLTokenAccount.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 29/04/2026.
//

public struct SPLTokenAccount: Sendable, Equatable, Hashable {
    public let mint: Pubkey
    public let address: Pubkey
    public let amount: UInt64
    public let decimals: UInt8
    public let programId: Pubkey
    public let name: String?
    public let symbol: String?

    public init(
        mint: Pubkey,
        address: Pubkey,
        amount: UInt64,
        decimals: UInt8,
        programId: Pubkey,
        name: String? = nil,
        symbol: String? = nil
    ) {
        self.mint = mint
        self.address = address
        self.amount = amount
        self.decimals = decimals
        self.programId = programId
        self.name = name
        self.symbol = symbol
    }

    public var uiAmount: Double {
        var divisor: Double = 1
        for _ in 0..<Int(decimals) {
            divisor *= 10
        }
        return Double(amount) / divisor
    }
}

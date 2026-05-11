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
    public let name: String?
    public let symbol: String?

    public init(
        mint: Pubkey,
        address: Pubkey,
        amount: UInt64,
        decimals: UInt8,
        name: String? = nil,
        symbol: String? = nil
    ) {
        self.mint = mint
        self.address = address
        self.amount = amount
        self.decimals = decimals
        self.name = name
        self.symbol = symbol
    }
}

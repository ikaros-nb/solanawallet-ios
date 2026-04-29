//
//  SPLTokenAccount.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 29/04/2026.
//

public struct SPLTokenAccount: Sendable, Equatable, Hashable {
    public let mint: PublicKey
    public let address: PublicKey
    public let amount: UInt64
    public let decimals: UInt8

    public init(
        mint: PublicKey,
        address: PublicKey,
        amount: UInt64,
        decimals: UInt8
    ) {
        self.mint = mint
        self.address = address
        self.amount = amount
        self.decimals = decimals
    }
}

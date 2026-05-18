//
//  SPLTokenRef.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 18/05/2026.
//

public struct SPLTokenRef: Sendable, Equatable, Hashable {
    public let mint: Pubkey
    public let programId: Pubkey
    public let decimals: UInt8

    public init(mint: Pubkey, programId: Pubkey, decimals: UInt8) {
        self.mint = mint
        self.programId = programId
        self.decimals = decimals
    }
}

public extension SPLTokenAccount {
    var ref: SPLTokenRef {
        SPLTokenRef(mint: mint, programId: programId, decimals: decimals)
    }
}

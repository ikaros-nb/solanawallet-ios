//
//  VaultAccount.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 04/05/2026.
//

public struct VaultAccount: Sendable, Equatable {
    public let owner: Pubkey
    public let bump: UInt8
    public let mint: Pubkey

    public init(owner: Pubkey, bump: UInt8, mint: Pubkey) {
        self.owner = owner
        self.bump = bump
        self.mint = mint
    }
}

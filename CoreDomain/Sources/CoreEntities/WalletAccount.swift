//
//  WalletAccount.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 01/05/2026.
//

public struct WalletAccount: Sendable, Equatable {
    public let pubkey: Pubkey

    public init(pubkey: Pubkey) {
        self.pubkey = pubkey
    }
}

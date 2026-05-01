//
//  WalletCreationResult.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 01/05/2026.
//

public struct WalletCreationResult: Sendable {
    public let account: WalletAccount
    public let seedPhrase: String

    public init(account: WalletAccount, seedPhrase: String) {
        self.account = account
        self.seedPhrase = seedPhrase
    }
}

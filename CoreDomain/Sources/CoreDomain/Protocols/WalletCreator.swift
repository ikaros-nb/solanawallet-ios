//
//  WalletCreator.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 01/05/2026.
//

import CoreEntities

public protocol WalletCreator: Sendable {
    func generateSeedPhrase() -> SecureSeedPhrase
    func createWallet(seedPhrase: SecureSeedPhrase) async throws -> WalletAccount
    func importWallet(seedPhrase: String) async throws -> WalletAccount
}

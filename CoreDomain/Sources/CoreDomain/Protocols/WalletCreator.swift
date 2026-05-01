//
//  WalletCreator.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 01/05/2026.
//

import CoreEntities

public protocol WalletCreator: Sendable {
    func createWallet() async throws -> WalletCreationResult
    func importWallet(seedPhrase: String) async throws -> WalletAccount
}

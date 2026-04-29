//
//  WalletReader.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 29/04/2026.
//

import CoreEntities

public protocol WalletReader: Sendable {
    func fetchBalance(for owner: Pubkey) async throws -> Lamports
    func fetchTokenAccounts(for owner: Pubkey) async throws -> [SPLTokenAccount]
}

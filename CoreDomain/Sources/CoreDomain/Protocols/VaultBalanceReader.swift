//
//  VaultBalanceReader.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 13/05/2026.
//

import CoreEntities
import Foundation

public protocol VaultBalanceReader: Sendable {
    func fetchVaultBalance(for owner: Pubkey) async throws -> Decimal
}

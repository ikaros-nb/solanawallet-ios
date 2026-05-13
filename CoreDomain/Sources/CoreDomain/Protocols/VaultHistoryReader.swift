//
//  VaultHistoryReader.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 13/05/2026.
//

import CoreEntities
import Foundation

public protocol VaultHistoryReader: Sendable {
    func fetchVaultTransactions(for owner: Pubkey, limit: Int) async throws -> [VaultTransaction]
}

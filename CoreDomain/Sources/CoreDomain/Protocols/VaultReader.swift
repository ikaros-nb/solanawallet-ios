//
//  VaultReader.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 13/05/2026.
//

import CoreEntities
import Foundation

public protocol VaultReader: Sendable {
    func fetchVaultBalance(for owner: Pubkey) async throws -> Decimal
}

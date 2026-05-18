//
//  VaultStateReader.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 18/05/2026.
//

import CoreEntities
import Foundation

public protocol VaultStateReader: Sendable {
    func fetchVaultExists(for owner: Pubkey) async throws -> Bool
}

//
//  VaultTransactor.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 13/05/2026.
//

import CoreEntities
import Foundation

public protocol VaultTransactor: Sendable {
    func depositVault(owner: Pubkey, amount: Decimal) async throws -> TransactionSignature
    func withdrawVault(owner: Pubkey, amount: Decimal) async throws -> TransactionSignature
}

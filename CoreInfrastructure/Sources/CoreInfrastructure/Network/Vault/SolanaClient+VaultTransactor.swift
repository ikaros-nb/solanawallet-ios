//
//  SolanaClient+VaultTransactor.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 15/05/2026.
//

import CoreDomain
import CoreEntities
import Foundation

extension SolanaClient: VaultTransactor {
    public func initializeVault(owner: Pubkey) async throws -> TransactionSignature {
        let instruction = try VaultProgram.initializeInstruction(owner: owner)
        let signature = try await submitInstruction(
            instruction,
            owner: owner,
            reason: "Initialize your VLT vault"
        )
        invalidateVaultCaches(for: owner)
        return signature
    }

    public func depositVault(owner: Pubkey, amount: Decimal) async throws -> TransactionSignature {
        let instruction = try VaultProgram.depositInstruction(owner: owner, amount: amount)
        let signature = try await submitInstruction(
            instruction,
            owner: owner,
            reason: "Confirm vault deposit"
        )
        invalidateVaultCaches(for: owner)
        return signature
    }

    public func withdrawVault(owner: Pubkey, amount: Decimal) async throws -> TransactionSignature {
        let instruction = try VaultProgram.withdrawInstruction(owner: owner, amount: amount)
        let signature = try await submitInstruction(
            instruction,
            owner: owner,
            reason: "Confirm vault withdrawal"
        )
        invalidateVaultCaches(for: owner)
        return signature
    }
}

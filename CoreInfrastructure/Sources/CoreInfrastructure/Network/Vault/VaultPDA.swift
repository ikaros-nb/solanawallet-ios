//
//  VaultPDA.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 15/05/2026.
//

import CoreEntities
import Foundation
@preconcurrency import SolanaSwift

enum VaultPDA {
    struct InstructionAccounts {
        let payer: PublicKey
        let vault: PublicKey
        let mint: PublicKey
        let payerTokenAccount: PublicKey
        let vaultTokenAccount: PublicKey
        let programId: PublicKey
    }

    static func vault(for owner: Pubkey) throws -> PublicKey {
        let programId = try PublicKey(string: VaultProgram.id)
        let ownerKey = try PublicKey(string: owner)
        return try deriveVault(programId: programId, owner: ownerKey)
    }

    static func vaultTokenAccount(for owner: Pubkey) throws -> PublicKey {
        let programId = try PublicKey(string: VaultProgram.id)
        let ownerKey = try PublicKey(string: owner)
        let vault = try deriveVault(programId: programId, owner: ownerKey)
        return try deriveVaultTokenAccount(programId: programId, vault: vault)
    }

    static func instructionAccounts(owner: Pubkey) throws -> InstructionAccounts {
        let programId = try PublicKey(string: VaultProgram.id)
        let payer = try PublicKey(string: owner)
        let mint = try PublicKey(string: VLT.mint)
        let vault = try deriveVault(programId: programId, owner: payer)
        let vaultTokenAccount = try deriveVaultTokenAccount(programId: programId, vault: vault)
        let payerTokenAccount = try PublicKey.associatedTokenAddress(
            walletAddress: payer,
            tokenMintAddress: mint,
            tokenProgramId: TokenProgram.id
        )
        return InstructionAccounts(
            payer: payer,
            vault: vault,
            mint: mint,
            payerTokenAccount: payerTokenAccount,
            vaultTokenAccount: vaultTokenAccount,
            programId: programId
        )
    }

    private static func deriveVault(
        programId: PublicKey,
        owner: PublicKey
    ) throws -> PublicKey {
        let (vault, _) = try PublicKey.findProgramAddress(
            seeds: [Data(VaultProgram.vaultSeed.utf8), owner.data],
            programId: programId
        )
        return vault
    }

    private static func deriveVaultTokenAccount(
        programId: PublicKey,
        vault: PublicKey
    ) throws -> PublicKey {
        let (tokenAccount, _) = try PublicKey.findProgramAddress(
            seeds: [Data(VaultProgram.tokenSeed.utf8), vault.data],
            programId: programId
        )
        return tokenAccount
    }
}

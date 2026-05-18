//
//  VaultProgram+ABI.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 18/05/2026.
//

import CoreDomain
import CoreEntities
import Foundation
@preconcurrency import SolanaSwift

extension VaultProgram {
    struct InstructionAccounts {
        let payer: PublicKey
        let vault: PublicKey
        let mint: PublicKey
        let payerTokenAccount: PublicKey
        let vaultTokenAccount: PublicKey
        let programId: PublicKey
    }

    static func statePDA(for owner: Pubkey) throws -> PublicKey {
        let programId = try PublicKey(string: id)
        let ownerKey = try PublicKey(string: owner)
        return try deriveState(programId: programId, owner: ownerKey)
    }

    static func tokenAccountPDA(for owner: Pubkey) throws -> PublicKey {
        let programId = try PublicKey(string: id)
        let ownerKey = try PublicKey(string: owner)
        let state = try deriveState(programId: programId, owner: ownerKey)
        return try deriveTokenAccount(programId: programId, state: state)
    }

    static func instructionAccounts(owner: Pubkey) throws -> InstructionAccounts {
        let programId = try PublicKey(string: id)
        let payer = try PublicKey(string: owner)
        let mint = try PublicKey(string: VLT.mint)
        let vault = try deriveState(programId: programId, owner: payer)
        let vaultTokenAccount = try deriveTokenAccount(programId: programId, state: vault)
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

    static func depositInstruction(
        owner: Pubkey,
        amount: Decimal
    ) throws -> TransactionInstruction {
        let scaled = try VaultAmount.scale(amount)
        return try makeInstruction(data: encodeAmountInstruction(name: "deposit", amount: scaled), owner: owner)
    }

    static func withdrawInstruction(
        owner: Pubkey,
        amount: Decimal
    ) throws -> TransactionInstruction {
        let scaled = try VaultAmount.scale(amount)
        return try makeInstruction(data: encodeAmountInstruction(name: "withdraw", amount: scaled), owner: owner)
    }

    static func encodeAmountInstruction(name: String, amount: UInt64) -> Data {
        let disc = BorshCoder.instructionDiscriminator(name: name)
        let amountLE = withUnsafeBytes(of: amount.littleEndian) { Data($0) }
        return disc + amountLE
    }

    private static func makeInstruction(
        data: Data,
        owner: Pubkey
    ) throws -> TransactionInstruction {
        let accounts: InstructionAccounts
        do {
            accounts = try instructionAccounts(owner: owner)
        } catch {
            throw WalletError.vaultError(code: 0, message: "account derivation failed: \(error)")
        }
        return TransactionInstruction(
            keys: [
                AccountMeta(publicKey: accounts.payer, isSigner: true, isWritable: true),
                AccountMeta(publicKey: accounts.vault, isSigner: false, isWritable: false),
                AccountMeta(publicKey: accounts.mint, isSigner: false, isWritable: false),
                AccountMeta(publicKey: accounts.payerTokenAccount, isSigner: false, isWritable: true),
                AccountMeta(publicKey: accounts.vaultTokenAccount, isSigner: false, isWritable: true),
                AccountMeta(publicKey: TokenProgram.id, isSigner: false, isWritable: false)
            ],
            programId: accounts.programId,
            data: [data]
        )
    }

    private static func deriveState(
        programId: PublicKey,
        owner: PublicKey
    ) throws -> PublicKey {
        let (state, _) = try PublicKey.findProgramAddress(
            seeds: [Data(vaultSeed.utf8), owner.data],
            programId: programId
        )
        return state
    }

    private static func deriveTokenAccount(
        programId: PublicKey,
        state: PublicKey
    ) throws -> PublicKey {
        let (tokenAccount, _) = try PublicKey.findProgramAddress(
            seeds: [Data(tokenSeed.utf8), state.data],
            programId: programId
        )
        return tokenAccount
    }
}

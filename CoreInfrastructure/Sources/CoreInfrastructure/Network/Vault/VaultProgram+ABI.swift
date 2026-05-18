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

public enum VaultInstructionDecodingError: Error, Equatable, Sendable {
    case invalidInputData
    case invalidDiscriminator(expected: Data, got: Data)
}

extension VaultProgram {
    enum InstructionKind: Equatable {
        case deposit
        case withdraw
    }

    struct InstructionAccounts {
        let payer: PublicKey
        let vault: PublicKey
        let mint: PublicKey
        let payerTokenAccount: PublicKey
        let vaultTokenAccount: PublicKey
        let programId: PublicKey
    }

    struct InitializeAccounts {
        let payer: PublicKey
        let vault: PublicKey
        let tokenAccount: PublicKey
        let mint: PublicKey
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

    static func initializeAccounts(owner: Pubkey) throws -> InitializeAccounts {
        let programId = try PublicKey(string: id)
        let payer = try PublicKey(string: owner)
        let mint = try PublicKey(string: VLT.mint)
        let vault = try deriveState(programId: programId, owner: payer)
        let tokenAccount = try deriveTokenAccount(programId: programId, state: vault)
        return InitializeAccounts(
            payer: payer,
            vault: vault,
            tokenAccount: tokenAccount,
            mint: mint,
            programId: programId
        )
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

    static func initializeInstruction(owner: Pubkey) throws -> TransactionInstruction {
        let accounts: InitializeAccounts
        do {
            accounts = try initializeAccounts(owner: owner)
        } catch {
            throw WalletError.vaultError(code: 0, message: "account derivation failed: \(error)")
        }
        return TransactionInstruction(
            keys: [
                AccountMeta(publicKey: accounts.payer, isSigner: true, isWritable: true),
                AccountMeta(publicKey: accounts.vault, isSigner: false, isWritable: true),
                AccountMeta(publicKey: accounts.tokenAccount, isSigner: false, isWritable: true),
                AccountMeta(publicKey: accounts.mint, isSigner: false, isWritable: false),
                AccountMeta(publicKey: TokenProgram.id, isSigner: false, isWritable: false),
                AccountMeta(publicKey: SystemProgram.id, isSigner: false, isWritable: false)
            ],
            programId: accounts.programId,
            data: [encodeInitializeInstruction()]
        )
    }

    static func encodeInitializeInstruction() -> Data {
        AnchorDiscriminator.instructionDiscriminator(name: "initialize")
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
        let disc = AnchorDiscriminator.instructionDiscriminator(name: name)
        let amountLE = withUnsafeBytes(of: amount.littleEndian) { Data($0) }
        return disc + amountLE
    }

    static func decodeInstruction(
        _ data: Data
    ) throws -> (kind: InstructionKind, amount: UInt64) {
        let discLen = 8
        let amountLen = MemoryLayout<UInt64>.size
        guard data.count >= discLen + amountLen else {
            throw VaultInstructionDecodingError.invalidInputData
        }

        let receivedDisc = data.prefix(discLen)
        let depositDisc = AnchorDiscriminator.instructionDiscriminator(name: "deposit")
        let withdrawDisc = AnchorDiscriminator.instructionDiscriminator(name: "withdraw")

        let kind: InstructionKind
        if receivedDisc == depositDisc {
            kind = .deposit
        } else if receivedDisc == withdrawDisc {
            kind = .withdraw
        } else {
            throw VaultInstructionDecodingError.invalidDiscriminator(
                expected: depositDisc,
                got: Data(receivedDisc)
            )
        }

        let amountRange = discLen..<(discLen + amountLen)
        let amount = data[amountRange].withUnsafeBytes { raw in
            raw.loadUnaligned(as: UInt64.self)
        }.littleEndian

        return (kind, amount)
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

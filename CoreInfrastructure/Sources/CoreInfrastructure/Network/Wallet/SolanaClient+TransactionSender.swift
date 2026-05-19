//
//  SolanaClient+TransactionSender.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 15/05/2026.
//

import CoreDomain
import CoreEntities
@preconcurrency import SolanaSwift

extension SolanaClient: TransactionSender {
    public func sendSOL(
        from owner: Pubkey,
        to recipient: Pubkey,
        amount: Lamports
    ) async throws -> TransactionSignature {
        let fromKey = try decodePublicKey(owner, role: "sender")
        let toKey = try decodePublicKey(recipient, role: "recipient")

        guard fromKey.base58EncodedString != toKey.base58EncodedString else {
            throw WalletError.sendToSelf
        }

        let recipientExists = try await recipientWalletExists(recipient: recipient)
        if !recipientExists {
            try await ensureAboveRentMinimum(amount: amount)
        }

        let instruction = SystemProgram.transferInstruction(
            from: fromKey,
            to: toKey,
            lamports: amount
        )
        let signature = try await submitInstruction(
            instruction,
            owner: owner,
            reason: "Confirm SOL transfer"
        )
        balanceCache.removeValue(forKey: owner)
        return signature
    }

    public func sendSPL(
        from owner: Pubkey,
        token: SPLTokenRef,
        to recipient: Pubkey,
        amount: UInt64
    ) async throws -> TransactionSignature {
        let ownerKey = try decodePublicKey(owner, role: "sender")
        let recipientKey = try decodePublicKey(recipient, role: "recipient")
        let mintKey = try decodePublicKey(token.mint, role: "mint")
        let programIdKey = try decodePublicKey(token.programId, role: "token program")

        guard ownerKey.base58EncodedString != recipientKey.base58EncodedString else {
            throw WalletError.sendToSelf
        }

        try await assertRecipientIsWallet(recipient: recipient)

        let sourceATA = try PublicKey.associatedTokenAddress(
            walletAddress: ownerKey,
            tokenMintAddress: mintKey,
            tokenProgramId: programIdKey
        )
        let destinationATA = try PublicKey.associatedTokenAddress(
            walletAddress: recipientKey,
            tokenMintAddress: mintKey,
            tokenProgramId: programIdKey
        )

        let accounts = TransferAccounts(
            source: sourceATA,
            destination: destinationATA,
            mint: mintKey,
            owner: ownerKey,
            programId: programIdKey
        )

        let createATA = AssociatedTokenProgram.createIdempotentInstruction(
            associatedAccount: destinationATA,
            mint: mintKey,
            owner: recipientKey,
            payer: ownerKey,
            tokenProgramId: programIdKey
        )
        let instructions: [TransactionInstruction] = [
            createATA,
            buildTransferChecked(accounts: accounts, amount: amount, decimals: token.decimals)
        ]

        let signature = try await submitInstructions(
            instructions,
            owner: owner,
            reason: "Confirm token transfer"
        )
        tokensCache.removeValue(forKey: owner)
        balanceCache.removeValue(forKey: owner)
        return signature
    }

    private func decodePublicKey(_ value: Pubkey, role: String) throws -> PublicKey {
        do {
            return try PublicKey(string: value)
        } catch {
            throw WalletError.unknown(underlying: "invalid \(role) pubkey: \(error)")
        }
    }

    private func buildTransferChecked(
        accounts: TransferAccounts,
        amount: UInt64,
        decimals: UInt8
    ) -> TransactionInstruction {
        let isToken2022 = accounts.programId.base58EncodedString == Token2022Program.id.base58EncodedString
        if isToken2022 {
            return Token2022Program.transferCheckedInstruction(
                source: accounts.source,
                mint: accounts.mint,
                destination: accounts.destination,
                owner: accounts.owner,
                multiSigners: [],
                amount: amount,
                decimals: decimals
            )
        }
        return TokenProgram.transferCheckedInstruction(
            source: accounts.source,
            mint: accounts.mint,
            destination: accounts.destination,
            owner: accounts.owner,
            multiSigners: [],
            amount: amount,
            decimals: decimals
        )
    }

    /// Returns whether the recipient account exists *and* is a system-owned wallet.
    /// Throws `recipientNotWallet` if it exists but is owned by some other program.
    private func recipientWalletExists(recipient: Pubkey) async throws -> Bool {
        guard let info = try await loadRecipientAccountInfo(recipient) else {
            return false
        }
        guard info.owner == SystemProgram.id.base58EncodedString else {
            throw WalletError.recipientNotWallet
        }
        return true
    }

    /// Throws `recipientNotWallet` if the recipient account exists and is not system-owned.
    /// Returns silently if the recipient is a system-owned wallet or does not yet exist
    /// (which is fine for SPL transfers — the idempotent ATA creation handles that case).
    private func assertRecipientIsWallet(recipient: Pubkey) async throws {
        guard let info = try await loadRecipientAccountInfo(recipient) else { return }
        guard info.owner == SystemProgram.id.base58EncodedString else {
            throw WalletError.recipientNotWallet
        }
    }

    private func loadRecipientAccountInfo(_ recipient: Pubkey) async throws -> BufferInfo<EmptyInfo>? {
        do {
            return try await rpc.getAccountInfo(account: recipient)
        } catch let apiError as APIClientError where apiError == .couldNotRetrieveAccountInfo {
            return nil
        } catch {
            throw mapToWalletError(error)
        }
    }

    private func ensureAboveRentMinimum(amount: Lamports) async throws {
        let minRent: Lamports
        do {
            minRent = try await rpc.getMinimumBalanceForRentExemption(
                dataLength: 0,
                commitment: SolanaCommitment.default
            )
        } catch {
            throw mapToWalletError(error)
        }
        if amount < minRent {
            throw WalletError.belowRentExemption(minLamports: minRent)
        }
    }
}

private struct TransferAccounts {
    let source: PublicKey
    let destination: PublicKey
    let mint: PublicKey
    let owner: PublicKey
    let programId: PublicKey
}

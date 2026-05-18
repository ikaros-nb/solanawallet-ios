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
        let fromKey: PublicKey
        let toKey: PublicKey
        do {
            fromKey = try PublicKey(string: owner)
        } catch {
            throw WalletError.unknown(underlying: "invalid sender pubkey: \(error)")
        }
        do {
            toKey = try PublicKey(string: recipient)
        } catch {
            throw WalletError.unknown(underlying: "invalid recipient pubkey: \(error)")
        }

        guard fromKey.base58EncodedString != toKey.base58EncodedString else {
            throw WalletError.sendToSelf
        }

        let recipientExists = try await ensureRecipientIsWallet(recipient: recipient)
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

        _ = try await ensureRecipientIsWallet(recipient: recipient)

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

        let destinationExists: Bool
        do {
            destinationExists = try await rpc.checkIfAssociatedTokenAccountExists(
                owner: recipientKey,
                mint: token.mint,
                tokenProgramId: programIdKey
            )
        } catch {
            throw mapToWalletError(error)
        }

        let accounts = TransferAccounts(
            source: sourceATA,
            destination: destinationATA,
            mint: mintKey,
            owner: ownerKey,
            programId: programIdKey
        )

        var instructions: [TransactionInstruction] = []
        if !destinationExists {
            let createATA = try AssociatedTokenProgram.createAssociatedTokenAccountInstruction(
                mint: mintKey,
                owner: recipientKey,
                payer: ownerKey,
                tokenProgramId: programIdKey
            )
            instructions.append(createATA)
        }
        instructions.append(buildTransferChecked(accounts: accounts, amount: amount, decimals: token.decimals))

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

    private func ensureRecipientIsWallet(recipient: Pubkey) async throws -> Bool {
        do {
            let info: BufferInfo<EmptyInfo>? = try await rpc.getAccountInfo(account: recipient)
            guard let info else { return false }
            guard info.owner == SystemProgram.id.base58EncodedString else {
                throw WalletError.recipientNotWallet
            }
            return true
        } catch let apiError as APIClientError where apiError == .couldNotRetrieveAccountInfo {
            return false
        } catch let walletError as WalletError {
            throw walletError
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

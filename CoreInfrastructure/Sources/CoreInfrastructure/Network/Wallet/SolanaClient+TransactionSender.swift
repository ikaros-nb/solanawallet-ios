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
        from _: Pubkey,
        mint _: Pubkey,
        to _: Pubkey,
        amount _: UInt64
    ) async throws -> TransactionSignature {
        throw WalletError.unknown(underlying: "not implemented (S20)")
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

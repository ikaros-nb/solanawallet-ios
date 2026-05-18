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
}

//
//  SolanaClient+TransactionOrchestrator.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 18/05/2026.
//

import CoreDomain
import CoreEntities
import Foundation
@preconcurrency import SolanaSwift

extension SolanaClient {
    func submitInstruction(
        _ instruction: TransactionInstruction,
        owner: Pubkey,
        reason: String
    ) async throws -> TransactionSignature {
        try await submitInstructions([instruction], owner: owner, reason: reason)
    }

    func submitInstructions(
        _ instructions: [TransactionInstruction],
        owner: Pubkey,
        reason: String
    ) async throws -> TransactionSignature {
        let payer: PublicKey
        do {
            payer = try PublicKey(string: owner)
        } catch {
            throw WalletError.vaultError(code: 0, message: "invalid owner pubkey: \(error)")
        }

        let blockhash: String
        do {
            blockhash = try await rpc.getLatestBlockhash(commitment: SolanaCommitment.default)
        } catch {
            throw mapToWalletError(error)
        }

        let serialized = try signTransaction(
            instructions,
            payer: payer,
            blockhash: blockhash,
            reason: reason
        )

        guard
            let sendConfig = RequestConfiguration(
                encoding: "base64",
                preflightCommitment: SolanaCommitment.default
            )
        else {
            throw WalletError.unknown(underlying: "invalid RequestConfiguration")
        }

        let signature: TransactionSignature
        do {
            signature = try await rpc.sendTransaction(transaction: serialized, configs: sendConfig)
        } catch {
            throw mapToWalletError(error)
        }

        try await confirmSignature(signature)
        return signature
    }

    private func signTransaction(
        _ instructions: [TransactionInstruction],
        payer: PublicKey,
        blockhash: String,
        reason: String
    ) throws -> String {
        do {
            return try keychain.withSigningSession(reason: reason) { secretKey in
                let signer = KeyPair(phrase: [], publicKey: payer, secretKey: secretKey)
                var tx = Transaction(
                    instructions: instructions,
                    recentBlockhash: blockhash,
                    feePayer: payer
                )
                try tx.sign(signers: [signer])
                return try tx.serialize().base64EncodedString()
            }
        } catch KeychainWalletStore.Failure.userCancelled,
            KeychainWalletStore.Failure.biometryFailed {
            throw WalletError.signingFailed
        } catch let walletError as WalletError {
            throw walletError
        } catch {
            throw WalletError.signingFailed
        }
    }

    private func confirmSignature(_ signature: TransactionSignature) async throws {
        for await status in rpc.observeSignatureStatus(signature: signature, timeout: 60, delay: 2) {
            switch status {
            case .confirmed, .finalized:
                return
            case .sending:
                continue
            }
        }
        throw WalletError.transactionExpired
    }
}

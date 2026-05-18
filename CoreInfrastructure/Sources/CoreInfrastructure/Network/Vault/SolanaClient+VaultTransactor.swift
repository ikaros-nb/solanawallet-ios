//
//  SolanaClient+VaultTransactor.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 15/05/2026.
//

import CoreDomain
import CoreEntities
import Foundation
@preconcurrency import SolanaSwift

extension SolanaClient: VaultTransactor {
    public func depositVault(owner: Pubkey, amount: Decimal) async throws -> TransactionSignature {
        try await submitVaultInstruction(
            data: coder.encodeDeposit(amount: VaultAmount.scale(amount)),
            owner: owner,
            reason: "Confirm vault deposit"
        )
    }

    public func withdrawVault(owner: Pubkey, amount: Decimal) async throws -> TransactionSignature {
        try await submitVaultInstruction(
            data: coder.encodeWithdraw(amount: VaultAmount.scale(amount)),
            owner: owner,
            reason: "Confirm vault withdrawal"
        )
    }

    // swiftlint:disable:next function_body_length
    private func submitVaultInstruction(
        data: Data,
        owner: Pubkey,
        reason: String
    ) async throws -> TransactionSignature {
        let accounts: VaultPDA.InstructionAccounts
        do {
            accounts = try VaultPDA.instructionAccounts(owner: owner)
        } catch {
            throw WalletError.vaultError(code: 0, message: "account derivation failed: \(error)")
        }

        let instruction = TransactionInstruction(
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

        let blockhash: String
        do {
            blockhash = try await fetchLatestBlockhash(at: rpcEndpoint)
        } catch {
            throw mapToWalletError(error)
        }

        let serialized: String
        do {
            let payer = accounts.payer
            serialized = try keychain.withSigningSession(reason: reason) { secretKey in
                let signer = KeyPair(phrase: [], publicKey: payer, secretKey: secretKey)
                var tx = Transaction(
                    instructions: [instruction],
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

        guard
            let sendConfig = RequestConfiguration(
                encoding: "base64",
                preflightCommitment: "confirmed"
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

        invalidateVaultCaches(for: owner)

        return signature
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

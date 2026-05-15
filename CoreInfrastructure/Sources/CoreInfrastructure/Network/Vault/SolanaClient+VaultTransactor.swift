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
            data: coder.encodeDeposit(amount: Self.scaledAmount(amount)),
            owner: owner,
            reason: "Confirm vault deposit"
        )
    }

    public func withdrawVault(owner: Pubkey, amount: Decimal) async throws -> TransactionSignature {
        try await submitVaultInstruction(
            data: coder.encodeWithdraw(amount: Self.scaledAmount(amount)),
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
        let accounts: VaultInstructionAccounts
        do {
            accounts = try Self.deriveVaultInstructionAccounts(owner: owner)
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
            blockhash = try await fetchLatestBlockhash()
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

    private struct VaultInstructionAccounts {
        let payer: PublicKey
        let vault: PublicKey
        let mint: PublicKey
        let payerTokenAccount: PublicKey
        let vaultTokenAccount: PublicKey
        let programId: PublicKey
    }

    private static func deriveVaultInstructionAccounts(
        owner: Pubkey
    ) throws -> VaultInstructionAccounts {
        let programId = try PublicKey(string: VaultProgram.id)
        let payer = try PublicKey(string: owner)
        let mint = try PublicKey(string: VLT.mint)
        let (vault, _) = try PublicKey.findProgramAddress(
            seeds: [Data(VaultProgram.vaultSeed.utf8), payer.data],
            programId: programId
        )
        let (vaultTokenAccount, _) = try PublicKey.findProgramAddress(
            seeds: [Data(VaultProgram.tokenSeed.utf8), vault.data],
            programId: programId
        )
        let payerTokenAccount = try PublicKey.associatedTokenAddress(
            walletAddress: payer,
            tokenMintAddress: mint,
            tokenProgramId: TokenProgram.id
        )
        return VaultInstructionAccounts(
            payer: payer,
            vault: vault,
            mint: mint,
            payerTokenAccount: payerTokenAccount,
            vaultTokenAccount: vaultTokenAccount,
            programId: programId
        )
    }

    private static func scaledAmount(_ amount: Decimal) throws -> UInt64 {
        guard amount > 0 else {
            throw WalletError.vaultError(code: 6001, message: "amount must be greater than zero")
        }
        var scaled = amount * pow(10, Int(VLT.decimals))
        var rounded = Decimal()
        NSDecimalRound(&rounded, &scaled, 0, .down)
        let number = NSDecimalNumber(decimal: rounded)
        guard number.doubleValue.isFinite, number.uint64Value > 0 else {
            throw WalletError.vaultError(code: 6001, message: "amount must be greater than zero")
        }
        return number.uint64Value
    }

    private func fetchLatestBlockhash() async throws -> String {
        struct Envelope: Decodable {
            struct Body: Decodable {
                struct Value: Decodable { let blockhash: String }
                let value: Value
            }

            struct RPCError: Decodable { let code: Int
                let message: String
            }

            let result: Body?
            let error: RPCError?
        }

        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "id": UUID().uuidString,
            "method": "getLatestBlockhash",
            "params": [["commitment": "confirmed"]]
        ]

        var request = URLRequest(url: rpcEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, _) = try await URLSession.shared.data(for: request)
        let envelope = try JSONDecoder().decode(Envelope.self, from: data)
        if let error = envelope.error {
            throw WalletError.vaultError(code: error.code, message: error.message)
        }
        guard let blockhash = envelope.result?.value.blockhash else {
            throw WalletError.unknown(underlying: "missing blockhash in getLatestBlockhash response")
        }
        return blockhash
    }
}

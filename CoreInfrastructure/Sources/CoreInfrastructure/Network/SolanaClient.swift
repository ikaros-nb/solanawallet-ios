//
//  SolanaClient.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 29/04/2026.
//

// swiftlint:disable file_length
import CoreDomain
import CoreEntities
import Foundation
@preconcurrency import SolanaSwift

public actor SolanaClient {
    private let rpc: SolanaAPIClient
    private let rpcEndpoint: URL
    private let keychain: KeychainWalletStore
    private let tokenRepository: TokenRepository
    private let coder: BorshCoder

    private var balanceCache: [Pubkey: Lamports] = [:]
    private var tokensCache: [Pubkey: [SPLTokenAccount]] = [:]
    private var vaultBalanceCache: [Pubkey: Decimal] = [:]
    private var vaultHistoryCache: [Pubkey: [VaultTransaction]] = [:]

    public init(
        rpc: SolanaAPIClient,
        rpcEndpoint: URL,
        keychain: KeychainWalletStore,
        tokenRepository: TokenRepository,
        coder: BorshCoder = BorshCoder()
    ) {
        self.rpc = rpc
        self.rpcEndpoint = rpcEndpoint
        self.keychain = keychain
        self.tokenRepository = tokenRepository
        self.coder = coder
    }

    func invalidateCache() {
        balanceCache.removeAll()
        tokensCache.removeAll()
        vaultBalanceCache.removeAll()
        vaultHistoryCache.removeAll()
    }

    private func invalidateVaultCaches(for owner: Pubkey) {
        tokensCache.removeValue(forKey: owner)
        vaultBalanceCache.removeValue(forKey: owner)
        vaultHistoryCache.removeValue(forKey: owner)
    }
}

extension SolanaClient: WalletReader {
    public func fetchBalance(for owner: Pubkey) async throws -> Lamports {
        do {
            let lamports = try await rpc.getBalance(account: owner, commitment: nil)
            balanceCache[owner] = lamports
            return lamports
        } catch {
            let mapped = mapToWalletError(error)
            if let cached = balanceCache[owner] {
                throw WalletError.staleCache(cached, underlying: mapped)
            }
            throw mapped
        }
    }

    public func fetchTokenAccounts(for owner: Pubkey) async throws -> [SPLTokenAccount] {
        do {
            let raw = try await rpc.getTokenAccountsByOwner(
                pubkey: owner,
                params: .init(mint: nil, programId: TokenProgram.id.base58EncodedString),
                configs: .init(commitment: "confirmed", encoding: "base64")
            )

            let mints = raw.map(\.account.data.mint.base58EncodedString)
            let metadata = try await tokenRepository.get(addresses: mints)

            let accounts: [SPLTokenAccount] = try await withThrowingTaskGroup(
                of: SPLTokenAccount.self
            ) { group in
                for token in raw {
                    let address = token.pubkey
                    let mint = token.account.data.mint.base58EncodedString
                    let amount = token.account.data.lamports
                    let name: String?
                    let symbol: String?
                    if mint == VLT.mint {
                        name = VLT.tokenName
                        symbol = VLT.tokenSymbol
                    } else {
                        name = metadata[mint]?.name
                        symbol = metadata[mint]?.symbol
                    }
                    group.addTask { [rpc] in
                        let balance = try await rpc.getTokenAccountBalance(
                            pubkey: address,
                            commitment: nil
                        )
                        return SPLTokenAccount(
                            mint: mint,
                            address: address,
                            amount: amount,
                            decimals: balance.decimals ?? 0,
                            name: name,
                            symbol: symbol
                        )
                    }
                }
                var out: [SPLTokenAccount] = []
                for try await account in group {
                    out.append(account)
                }
                return out
            }

            tokensCache[owner] = accounts
            return accounts
        } catch {
            let mapped = mapToWalletError(error)
            if let cached = tokensCache[owner] {
                throw WalletError.staleTokenCache(cached, underlying: mapped)
            }
            throw mapped
        }
    }
}

extension SolanaClient: VaultBalanceReader {
    public func fetchVaultBalance(for owner: Pubkey) async throws -> Decimal {
        let tokenAccountPDA: PublicKey
        do {
            let programId = try PublicKey(string: VaultProgram.id)
            let ownerKey = try PublicKey(string: owner)
            let (vaultPDA, _) = try PublicKey.findProgramAddress(
                seeds: [Data(VaultProgram.vaultSeed.utf8), ownerKey.data],
                programId: programId
            )
            (tokenAccountPDA, _) = try PublicKey.findProgramAddress(
                seeds: [Data(VaultProgram.tokenSeed.utf8), vaultPDA.data],
                programId: programId
            )
        } catch {
            throw WalletError.vaultError(code: 0, message: "PDA derivation failed: \(error)")
        }

        do {
            let balance = try await rpc.getTokenAccountBalance(
                pubkey: tokenAccountPDA.base58EncodedString,
                commitment: nil
            )
            let decimal = try Self.decode(tokenAccountBalance: balance)
            vaultBalanceCache[owner] = decimal
            return decimal
        } catch let APIClientError.responseError(response) where Self.isAccountNotFound(response) {
            vaultBalanceCache[owner] = 0
            return 0
        } catch APIClientError.couldNotRetrieveAccountInfo {
            vaultBalanceCache[owner] = 0
            return 0
        } catch {
            let mapped = mapToWalletError(error)
            if let cached = vaultBalanceCache[owner] {
                throw WalletError.staleVaultCache(cached, underlying: mapped)
            }
            throw mapped
        }
    }

    private static let posix = Locale(identifier: "en_US_POSIX")

    private static func decode(tokenAccountBalance balance: TokenAccountBalance) throws -> Decimal {
        let uiDecimal = balance.uiAmountString.flatMap { Decimal(string: $0, locale: posix) }
        if let decimal = uiDecimal { return decimal }
        guard let rawAmount = UInt64(balance.amount), let decimals = balance.decimals else {
            throw WalletError.vaultError(code: 0, message: "invalid token account balance response")
        }
        return Decimal(rawAmount) / pow(10, Int(decimals))
    }

    private static func isAccountNotFound(_ response: ResponseError) -> Bool {
        if response.code == -32602 { return true }
        return response.message?.localizedCaseInsensitiveContains("could not find account") == true
    }
}

extension SolanaClient: VaultHistoryReader {
    public func fetchVaultTransactions(
        for owner: Pubkey,
        limit: Int
    ) async throws -> [VaultTransaction] {
        let vaultStatePDA: PublicKey
        do {
            vaultStatePDA = try Self.deriveVaultStatePDA(for: owner)
        } catch {
            throw WalletError.vaultError(code: 0, message: "PDA derivation failed: \(error)")
        }

        do {
            let address = vaultStatePDA.base58EncodedString
            let configs = RequestConfiguration(limit: limit)
            let infos = try await rpc.getSignaturesForAddress(address: address, configs: configs)
            let successful = infos.filter { $0.err == nil }

            let transactions = await fetchAndDecode(signatures: successful)
            let sorted = transactions.sorted { $0.timestamp > $1.timestamp }
            vaultHistoryCache[owner] = sorted
            return sorted
        } catch {
            let mapped = mapToWalletError(error)
            if let cached = vaultHistoryCache[owner] {
                throw WalletError.staleVaultHistoryCache(cached, underlying: mapped)
            }
            throw mapped
        }
    }

    private func fetchAndDecode(
        signatures: [SignatureInfo]
    ) async -> [VaultTransaction] {
        await withTaskGroup(of: VaultTransaction?.self) { group in
            for info in signatures {
                group.addTask { [rpc, coder] in
                    await Self.decodeTransaction(signatureInfo: info, rpc: rpc, coder: coder)
                }
            }
            var out: [VaultTransaction] = []
            for await tx in group {
                if let tx { out.append(tx) }
            }
            return out
        }
    }

    private static func decodeTransaction(
        signatureInfo: SignatureInfo,
        rpc: SolanaAPIClient,
        coder: BorshCoder
    ) async -> VaultTransaction? {
        do {
            guard
                let info = try await rpc.getTransaction(
                    signature: signatureInfo.signature,
                    commitment: nil
                ) else { return nil }
            guard info.meta?.err == nil else { return nil }
            guard let blockTime = info.blockTime ?? signatureInfo.blockTime else { return nil }

            guard
                let instruction = info.transaction.message.instructions.first(
                    where: { $0.programId == VaultProgram.id }
                ),
                let dataString = instruction.data else { return nil }

            let bytes = Base58.decode(dataString)
            guard !bytes.isEmpty else { return nil }

            let decoded = try coder.decodeVaultInstruction(from: Data(bytes))
            let scaled = Decimal(decoded.amount) / pow(10, Int(VLT.decimals))

            return VaultTransaction(
                signature: signatureInfo.signature,
                kind: decoded.kind == .deposit ? .deposit : .withdraw,
                amount: scaled,
                timestamp: Date(timeIntervalSince1970: TimeInterval(blockTime)),
                slot: signatureInfo.slot ?? info.slot ?? 0
            )
        } catch {
            return nil
        }
    }

    private static func deriveVaultStatePDA(for owner: Pubkey) throws -> PublicKey {
        let programId = try PublicKey(string: VaultProgram.id)
        let ownerKey = try PublicKey(string: owner)
        let (vaultPDA, _) = try PublicKey.findProgramAddress(
            seeds: [Data(VaultProgram.vaultSeed.utf8), ownerKey.data],
            programId: programId
        )
        return vaultPDA
    }
}

extension SolanaClient: TransactionSender {
    public func sendSOL(
        to recipient: Pubkey,
        amount: Lamports
    ) async throws -> TransactionSignature {
        throw WalletError.unknown(underlying: "not implemented (S20)")
    }

    public func sendSPL(
        mint: Pubkey,
        to recipient: Pubkey,
        amount: UInt64
    ) async throws -> TransactionSignature {
        throw WalletError.unknown(underlying: "not implemented (S20)")
    }
}

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

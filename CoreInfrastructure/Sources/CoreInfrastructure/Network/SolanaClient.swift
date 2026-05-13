//
//  SolanaClient.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 29/04/2026.
//

import CoreDomain
import CoreEntities
import Foundation
@preconcurrency import SolanaSwift

public actor SolanaClient {
    private static let vaultTokenMint: Pubkey = VLT.mint
    private static let vaultTokenName = "Vault Token"
    private static let vaultTokenSymbol = "VLT"

    private let rpc: SolanaAPIClient
    private let keychain: KeychainWalletStore
    private let tokenRepository: TokenRepository?
    private var balanceCache: [Pubkey: Lamports] = [:]
    private var tokensCache: [Pubkey: [SPLTokenAccount]] = [:]
    private var vaultBalanceCache: [Pubkey: Decimal] = [:]

    public init(
        rpc: SolanaAPIClient,
        keychain: KeychainWalletStore,
        tokenRepository: TokenRepository? = nil
    ) {
        self.rpc = rpc
        self.keychain = keychain
        self.tokenRepository = tokenRepository
    }

    func invalidateCache() {
        balanceCache.removeAll()
        tokensCache.removeAll()
        vaultBalanceCache.removeAll()
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
            let metadata = try? await tokenRepository?.get(addresses: mints)

            let accounts: [SPLTokenAccount] = try await withThrowingTaskGroup(
                of: SPLTokenAccount.self
            ) { group in
                for token in raw {
                    let address = token.pubkey
                    let mint = token.account.data.mint.base58EncodedString
                    let amount = token.account.data.lamports
                    let name: String?
                    let symbol: String?
                    if mint == Self.vaultTokenMint {
                        name = Self.vaultTokenName
                        symbol = Self.vaultTokenSymbol
                    } else {
                        name = metadata?[mint]?.name
                        symbol = metadata?[mint]?.symbol
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

extension SolanaClient: VaultReader {
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

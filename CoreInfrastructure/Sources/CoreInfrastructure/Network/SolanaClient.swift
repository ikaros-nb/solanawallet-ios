//
//  SolanaClient.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 29/04/2026.
//

import CoreDomain
import CoreEntities
@preconcurrency import SolanaSwift

public actor SolanaClient {
    private let rpc: SolanaAPIClient
    private let keychain: KeychainWalletStore
    private var balanceCache: [Pubkey: Lamports] = [:]
    private var tokensCache: [Pubkey: [SPLTokenAccount]] = [:]

    public init(rpc: SolanaAPIClient, keychain: KeychainWalletStore) {
        self.rpc = rpc
        self.keychain = keychain
    }

    func invalidateCache() {
        balanceCache.removeAll()
        tokensCache.removeAll()
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

            let accounts: [SPLTokenAccount] = try await withThrowingTaskGroup(
                of: SPLTokenAccount.self
            ) { group in
                for token in raw {
                    let address = token.pubkey
                    let mint = token.account.data.mint.base58EncodedString
                    let amount = token.account.data.lamports
                    group.addTask { [rpc] in
                        let balance = try await rpc.getTokenAccountBalance(
                            pubkey: address,
                            commitment: nil
                        )
                        return SPLTokenAccount(
                            mint: mint,
                            address: address,
                            amount: amount,
                            decimals: balance.decimals ?? 0
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

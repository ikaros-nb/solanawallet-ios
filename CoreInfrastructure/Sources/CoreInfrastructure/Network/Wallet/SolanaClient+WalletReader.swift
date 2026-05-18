//
//  SolanaClient+WalletReader.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 15/05/2026.
//

import CoreDomain
import CoreEntities
import Foundation
@preconcurrency import SolanaSwift

extension SolanaClient: WalletReader {
    public func fetchBalance(for owner: Pubkey) async throws -> Lamports {
        do {
            let lamports = try await rpc.getBalance(account: owner, commitment: nil)
            balanceCache[owner] = lamports
            return lamports
        } catch {
            throw mapToStaleCacheError(error, cached: balanceCache[owner]) {
                .staleCache($0, underlying: $1)
            }
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
            throw mapToStaleCacheError(error, cached: tokensCache[owner]) {
                .staleTokenCache($0, underlying: $1)
            }
        }
    }
}

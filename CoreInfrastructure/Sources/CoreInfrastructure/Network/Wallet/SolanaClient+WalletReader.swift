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
            let lamports = try await rpc.getBalance(account: owner, commitment: SolanaCommitment.default)
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
            async let classicRaw = rpc.getTokenAccountsByOwner(
                pubkey: owner,
                params: .init(mint: nil, programId: TokenProgram.id.base58EncodedString),
                configs: RequestConfiguration(commitment: SolanaCommitment.default, encoding: "base64")
            )
            async let token2022Raw = rpc.getTokenAccountsByOwner(
                pubkey: owner,
                params: .init(mint: nil, programId: Token2022Program.id.base58EncodedString),
                configs: RequestConfiguration(commitment: SolanaCommitment.default, encoding: "base64")
            )
            let classic = try await classicRaw
            let token2022 = try await token2022Raw

            let classicProgramId = TokenProgram.id.base58EncodedString
            let token2022ProgramId = Token2022Program.id.base58EncodedString

            let allMints = classic.map(\.account.data.mint.base58EncodedString)
                + token2022.map(\.account.data.mint.base58EncodedString)
            let uniqueMints = Array(Set(allMints))

            async let metadataTask = tokenRepository.get(addresses: allMints)
            // TokenMintState decodes the 82-byte mint prefix shared by SPL Token and Token-2022,
            // so this single batch covers both programs.
            async let mintDatasTask = rpc.getMultipleMintDatas(
                mintAddresses: uniqueMints,
                commitment: SolanaCommitment.default,
                mintType: TokenMintState.self
            )
            let metadata = try await metadataTask
            let mintDatas = try await mintDatasTask

            var seeds: [TokenAccountSeed] = []
            seeds.reserveCapacity(classic.count + token2022.count)
            for token in classic {
                seeds.append(makeSeed(token: token, programId: classicProgramId, metadata: metadata))
            }
            for token in token2022 {
                seeds.append(makeSeed(token: token, programId: token2022ProgramId, metadata: metadata))
            }

            let accounts: [SPLTokenAccount] = seeds.map { seed in
                SPLTokenAccount(
                    mint: seed.mint,
                    address: seed.address,
                    amount: seed.amount,
                    decimals: mintDatas[seed.mint]?.decimals ?? 0,
                    programId: seed.programId,
                    name: seed.name,
                    symbol: seed.symbol
                )
            }

            tokensCache[owner] = accounts
            return accounts
        } catch {
            throw mapToStaleCacheError(error, cached: tokensCache[owner]) {
                .staleTokenCache($0, underlying: $1)
            }
        }
    }

    private func makeSeed(
        token: TokenAccount<TokenAccountState>,
        programId: Pubkey,
        metadata: [String: TokenMetadata]
    ) -> TokenAccountSeed {
        let mint = token.account.data.mint.base58EncodedString
        let name: String?
        let symbol: String?
        if mint == VLT.mint {
            name = VLT.tokenName
            symbol = VLT.tokenSymbol
        } else {
            name = metadata[mint]?.name
            symbol = metadata[mint]?.symbol
        }
        return TokenAccountSeed(
            address: token.pubkey,
            mint: mint,
            amount: token.account.data.lamports,
            programId: programId,
            name: name,
            symbol: symbol
        )
    }
}

private struct TokenAccountSeed {
    let address: Pubkey
    let mint: Pubkey
    let amount: UInt64
    let programId: Pubkey
    let name: String?
    let symbol: String?
}

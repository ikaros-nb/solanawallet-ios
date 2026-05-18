//
//  SolanaClient+VaultHistoryReader.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 15/05/2026.
//

import CoreDomain
import CoreEntities
import Foundation
@preconcurrency import SolanaSwift

extension SolanaClient: VaultHistoryReader {
    public func fetchVaultTransactions(
        for owner: Pubkey,
        limit: Int
    ) async throws -> [VaultTransaction] {
        let vaultStatePDA: PublicKey
        do {
            vaultStatePDA = try VaultProgram.statePDA(for: owner)
        } catch {
            throw WalletError.vaultError(code: 0, message: "PDA derivation failed: \(error)")
        }

        do {
            let address = vaultStatePDA.base58EncodedString
            let configs = RequestConfiguration(commitment: SolanaCommitment.default, limit: limit)
            let infos = try await rpc.getSignaturesForAddress(address: address, configs: configs)
            let successful = infos.filter { $0.err == nil }

            let transactions = await fetchAndDecode(signatures: successful)
            let sorted = transactions.sorted { $0.timestamp > $1.timestamp }
            vaultHistoryCache[owner] = sorted
            return sorted
        } catch {
            throw mapToStaleCacheError(error, cached: vaultHistoryCache[owner]) {
                .staleVaultHistoryCache($0, underlying: $1)
            }
        }
    }

    private static let maxConcurrentTransactionFetches = 4

    private func fetchAndDecode(
        signatures: [SignatureInfo]
    ) async -> [VaultTransaction] {
        let fetch: @Sendable (SignatureInfo) async -> VaultTransaction? = { [rpc] signatureInfo in
            let info = try? await rpc.getTransaction(
                signature: signatureInfo.signature,
                commitment: SolanaCommitment.default
            )
            return VaultTransactionDecoder.decode(signatureInfo: signatureInfo, info: info)
        }

        return await withTaskGroup(of: VaultTransaction?.self) { group in
            var iterator = signatures.makeIterator()
            var inFlight = 0
            while inFlight < Self.maxConcurrentTransactionFetches, let next = iterator.next() {
                group.addTask { await fetch(next) }
                inFlight += 1
            }

            var out: [VaultTransaction] = []
            while let result = await group.next() {
                if let tx = result { out.append(tx) }
                if let next = iterator.next() {
                    group.addTask { await fetch(next) }
                }
            }
            return out
        }
    }
}

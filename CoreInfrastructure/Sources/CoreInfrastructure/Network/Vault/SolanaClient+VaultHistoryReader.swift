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

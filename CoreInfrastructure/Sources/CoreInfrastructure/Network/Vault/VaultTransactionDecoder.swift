//
//  VaultTransactionDecoder.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 18/05/2026.
//

import CoreEntities
import Foundation
@preconcurrency import SolanaSwift

enum VaultTransactionDecoder {
    static func decode(
        signatureInfo: SignatureInfo,
        rpc: SolanaAPIClient,
        coder: BorshCoder
    ) async -> VaultTransaction? {
        do {
            guard
                let info = try await rpc.getTransaction(
                    signature: signatureInfo.signature,
                    commitment: SolanaCommitment.default
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
}

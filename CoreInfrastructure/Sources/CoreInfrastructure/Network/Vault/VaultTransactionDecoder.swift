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
        info: TransactionInfo?
    ) -> VaultTransaction? {
        guard let info else { return nil }
        guard info.meta?.err == nil else { return nil }
        guard let blockTime = info.blockTime ?? signatureInfo.blockTime else { return nil }

        guard
            let instruction = info.transaction.message.instructions.first(
                where: { $0.programId == VaultProgram.id }
            ),
            let dataString = instruction.data else { return nil }

        let bytes = Base58.decode(dataString)
        guard !bytes.isEmpty else { return nil }

        guard let decoded = try? VaultProgram.decodeInstruction(Data(bytes)) else { return nil }
        let txKind: VaultTransaction.Kind = switch decoded.kind {
        case .deposit: .deposit
        case .withdraw: .withdraw
        }
        let scaled = Decimal(decoded.amount) / pow(10, Int(VLT.decimals))

        return VaultTransaction(
            signature: signatureInfo.signature,
            kind: txKind,
            amount: scaled,
            timestamp: Date(timeIntervalSince1970: TimeInterval(blockTime)),
            slot: signatureInfo.slot ?? info.slot ?? 0
        )
    }
}

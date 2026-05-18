//
//  VaultTransactionDecoderTests.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 18/05/2026.
//

import CoreEntities
import Foundation
@preconcurrency import SolanaSwift
import Testing
@testable import CoreInfrastructure

@Suite("VaultTransactionDecoder")
struct VaultTransactionDecoderTests {
    // MARK: Happy paths

    @Test
    func `decode returns a deposit VaultTransaction with kind, amount, slot, timestamp`() throws {
        let amount: UInt64 = 1_500_000_000
        let info = try makeTransactionInfo(
            instructionDataBase58: encode(name: "deposit", amount: amount),
            slot: 250,
            blockTime: 1_700_000_000
        )
        let signatureInfo = try makeSignatureInfo(signature: "deposit-sig", slot: 500, blockTime: 1_700_000_500)

        let result = VaultTransactionDecoder.decode(signatureInfo: signatureInfo, info: info)
        let tx = try #require(result)

        #expect(tx.signature == "deposit-sig")
        #expect(tx.kind == .deposit)
        // 1_500_000_000 / 10^9 == 1.5
        let expectedAmount = try #require(Decimal(string: "1.5", locale: Locale(identifier: "en_US_POSIX")))
        #expect(tx.amount == expectedAmount)
        // info.blockTime takes precedence over signatureInfo.blockTime
        #expect(tx.timestamp == Date(timeIntervalSince1970: 1_700_000_000))
        // signatureInfo.slot takes precedence over info.slot
        #expect(tx.slot == 500)
    }

    @Test
    func `decode returns a withdraw VaultTransaction`() throws {
        let info = try makeTransactionInfo(
            instructionDataBase58: encode(name: "withdraw", amount: 2_000_000_000),
            slot: 1,
            blockTime: 1
        )
        let signatureInfo = try makeSignatureInfo(signature: "w", slot: nil, blockTime: nil)

        let tx = try #require(VaultTransactionDecoder.decode(signatureInfo: signatureInfo, info: info))
        #expect(tx.kind == .withdraw)
        #expect(tx.amount == Decimal(2))
    }

    // MARK: Slot / blockTime fallback semantics

    @Test
    func `decode falls back to signatureInfo blockTime when info blockTime is nil`() throws {
        let info = try makeTransactionInfo(
            instructionDataBase58: encode(name: "deposit", amount: 1),
            blockTime: nil
        )
        let signatureInfo = try makeSignatureInfo(blockTime: 42)

        let tx = try #require(VaultTransactionDecoder.decode(signatureInfo: signatureInfo, info: info))
        #expect(tx.timestamp == Date(timeIntervalSince1970: 42))
    }

    @Test
    func `decode falls back to info slot when signatureInfo slot is nil`() throws {
        let info = try makeTransactionInfo(
            instructionDataBase58: encode(name: "deposit", amount: 1),
            slot: 9999,
            blockTime: 1
        )
        let signatureInfo = try makeSignatureInfo(slot: nil, blockTime: 1)

        let tx = try #require(VaultTransactionDecoder.decode(signatureInfo: signatureInfo, info: info))
        #expect(tx.slot == 9999)
    }

    // MARK: nil-returning failure modes

    @Test
    func `decode returns nil when info is nil`() throws {
        let signatureInfo = try makeSignatureInfo(blockTime: 1)
        #expect(VaultTransactionDecoder.decode(signatureInfo: signatureInfo, info: nil) == nil)
    }

    @Test
    func `decode returns nil when meta has non-null err`() throws {
        let info = try makeTransactionInfo(
            instructionDataBase58: encode(name: "deposit", amount: 1),
            metaErrJSON: "\"InstructionError\""
        )
        let signatureInfo = try makeSignatureInfo(blockTime: 1)
        #expect(VaultTransactionDecoder.decode(signatureInfo: signatureInfo, info: info) == nil)
    }

    @Test
    func `decode returns nil when no vault-program instruction is present`() throws {
        let info = try makeTransactionInfo(
            instructionDataBase58: encode(name: "deposit", amount: 1),
            instructionProgramId: "11111111111111111111111111111111",
            blockTime: 1
        )
        let signatureInfo = try makeSignatureInfo()
        #expect(VaultTransactionDecoder.decode(signatureInfo: signatureInfo, info: info) == nil)
    }

    @Test
    func `decode returns nil when instruction data is empty`() throws {
        let info = try makeTransactionInfo(instructionDataBase58: "", blockTime: 1)
        let signatureInfo = try makeSignatureInfo()
        #expect(VaultTransactionDecoder.decode(signatureInfo: signatureInfo, info: info) == nil)
    }

    @Test
    func `decode returns nil when instruction data contains invalid base58 characters`() throws {
        // "0OIl" all sit outside the Base58 alphabet; Base58.decode returns [].
        let info = try makeTransactionInfo(instructionDataBase58: "0OIl0OIl0OIl", blockTime: 1)
        let signatureInfo = try makeSignatureInfo()
        #expect(VaultTransactionDecoder.decode(signatureInfo: signatureInfo, info: info) == nil)
    }

    @Test
    func `decode returns nil when instruction data decodes to fewer than 16 bytes`() throws {
        // "1234" is valid base58 → decodes to a short non-empty byte array,
        // which VaultProgram.decodeInstruction rejects with .invalidInputData.
        let info = try makeTransactionInfo(instructionDataBase58: "1234", blockTime: 1)
        let signatureInfo = try makeSignatureInfo()
        #expect(VaultTransactionDecoder.decode(signatureInfo: signatureInfo, info: info) == nil)
    }

    @Test
    func `decode returns nil when instruction discriminator is unknown`() throws {
        // 16 bytes of 0xAA — well-formed length, no matching deposit/withdraw discriminator.
        let bogus = Data(repeating: 0xAA, count: 16)
        let info = try makeTransactionInfo(instructionDataBase58: Base58.encode(bogus), blockTime: 1)
        let signatureInfo = try makeSignatureInfo()
        #expect(VaultTransactionDecoder.decode(signatureInfo: signatureInfo, info: info) == nil)
    }

    @Test
    func `decode returns nil when both blockTime sources are nil`() throws {
        let info = try makeTransactionInfo(
            instructionDataBase58: encode(name: "deposit", amount: 1),
            blockTime: nil
        )
        let signatureInfo = try makeSignatureInfo(blockTime: nil)
        #expect(VaultTransactionDecoder.decode(signatureInfo: signatureInfo, info: info) == nil)
    }

    // MARK: Fixture helpers

    private func encode(name: String, amount: UInt64) -> String {
        Base58.encode(VaultProgram.encodeAmountInstruction(name: name, amount: amount))
    }

    private func makeSignatureInfo(
        signature: String = "sig",
        slot: UInt64? = nil,
        blockTime: UInt64? = nil
    ) throws -> SignatureInfo {
        let slotField = slot.map(String.init) ?? "null"
        let blockTimeField = blockTime.map(String.init) ?? "null"
        let json = """
        {
          "signature": "\(signature)",
          "slot": \(slotField),
          "err": null,
          "memo": null,
          "blockTime": \(blockTimeField)
        }
        """
        return try JSONDecoder().decode(SignatureInfo.self, from: Data(json.utf8))
    }

    private func makeTransactionInfo(
        instructionDataBase58: String,
        instructionProgramId: String = VaultProgram.id,
        metaErrJSON: String = "null",
        slot: UInt64 = 100,
        blockTime: UInt64? = 1_700_000_000
    ) throws -> TransactionInfo {
        let blockTimeField = blockTime.map(String.init) ?? "null"
        let json = """
        {
          "slot": \(slot),
          "blockTime": \(blockTimeField),
          "meta": { "err": \(metaErrJSON), "fee": 5000 },
          "transaction": {
            "signatures": ["sig"],
            "message": {
              "accountKeys": [],
              "instructions": [{
                "programId": "\(instructionProgramId)",
                "data": "\(instructionDataBase58)",
                "accounts": []
              }],
              "recentBlockhash": "11111111111111111111111111111111"
            }
          }
        }
        """
        return try JSONDecoder().decode(TransactionInfo.self, from: Data(json.utf8))
    }
}

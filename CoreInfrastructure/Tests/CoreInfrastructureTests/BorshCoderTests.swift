//
//  BorshCoderTests.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 04/05/2026.
//

import CoreEntities
import Foundation
import Testing
@testable import CoreInfrastructure

@Suite("BorshCoder")
struct BorshCoderTests {
    private let coder = BorshCoder()

    // MARK: Discriminators (golden vectors from idl/vault.json)

    @Test
    func `deposit instruction discriminator matches IDL`() {
        let expected = Data([242, 35, 198, 137, 82, 225, 242, 182])
        #expect(BorshCoder.instructionDiscriminator(name: "deposit") == expected)
    }

    @Test
    func `withdraw instruction discriminator matches IDL`() {
        let expected = Data([183, 18, 70, 156, 148, 109, 161, 34])
        #expect(BorshCoder.instructionDiscriminator(name: "withdraw") == expected)
    }

    @Test
    func `vaultState account discriminator matches IDL`() {
        let expected = Data([228, 196, 82, 165, 98, 210, 235, 152])
        #expect(BorshCoder.accountDiscriminator(name: "VaultState") == expected)
    }

    // MARK: Encode deposit

    @Test
    func `encodeDeposit with amount 1000 produces discriminator plus u64 little-endian`() {
        // 1000 == 0x3E8 → little-endian bytes: E8 03 00 00 00 00 00 00
        let expected = Data([242, 35, 198, 137, 82, 225, 242, 182])
            + Data([0xE8, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        #expect(coder.encodeDeposit(amount: 1000) == expected)
    }

    @Test
    func `encodeDeposit with zero amount produces discriminator plus eight zero bytes`() {
        let expected = Data([242, 35, 198, 137, 82, 225, 242, 182])
            + Data(repeating: 0x00, count: 8)
        #expect(coder.encodeDeposit(amount: 0) == expected)
    }

    @Test
    func `encodeDeposit with UInt64 max produces discriminator plus eight 0xFF bytes`() {
        let expected = Data([242, 35, 198, 137, 82, 225, 242, 182])
            + Data(repeating: 0xFF, count: 8)
        #expect(coder.encodeDeposit(amount: UInt64.max) == expected)
    }

    @Test
    func `encodeDeposit total layout is 16 bytes`() {
        #expect(coder.encodeDeposit(amount: 1000).count == 16)
    }

    // MARK: Encode withdraw

    @Test
    func `encodeWithdraw with amount 1000 produces discriminator plus u64 little-endian`() {
        let expected = Data([183, 18, 70, 156, 148, 109, 161, 34])
            + Data([0xE8, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        #expect(coder.encodeWithdraw(amount: 1000) == expected)
    }

    @Test
    func `encodeWithdraw with zero amount produces discriminator plus eight zero bytes`() {
        let expected = Data([183, 18, 70, 156, 148, 109, 161, 34])
            + Data(repeating: 0x00, count: 8)
        #expect(coder.encodeWithdraw(amount: 0) == expected)
    }

    @Test
    func `encodeWithdraw with UInt64 max produces discriminator plus eight 0xFF bytes`() {
        let expected = Data([183, 18, 70, 156, 148, 109, 161, 34])
            + Data(repeating: 0xFF, count: 8)
        #expect(coder.encodeWithdraw(amount: UInt64.max) == expected)
    }

    // MARK: Decode VaultState — error paths

    @Test
    func `decodeVaultAccount throws invalidInputData when data is too short`() {
        let tooShort = Data(repeating: 0x00, count: 10)
        #expect(throws: BorshCoderError.invalidInputData) {
            try coder.decodeVaultAccount(from: tooShort)
        }
    }

    @Test
    func `decodeVaultAccount throws invalidDiscriminator when prefix is wrong`() {
        let wrongDiscriminator = Data(repeating: 0xAA, count: 8)
        let payload = Data(repeating: 0x00, count: 32 + 1 + 32)
        let bytes = wrongDiscriminator + payload

        #expect {
            try coder.decodeVaultAccount(from: bytes)
        } throws: { error in
            guard case let BorshCoderError.invalidDiscriminator(expected, got) = error else {
                return false
            }
            return expected == BorshCoder.accountDiscriminator(name: "VaultState")
                && got == wrongDiscriminator
        }
    }
}

//
//  BorshCoderTests.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 04/05/2026.
//

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

    // MARK: Decode vault instruction

    @Test
    func `decodeVaultInstruction round-trips a deposit`() throws {
        let amount: UInt64 = 5_000_000
        let data = coder.encodeDeposit(amount: amount)
        let decoded = try coder.decodeVaultInstruction(from: data)
        #expect(decoded.kind == .deposit)
        #expect(decoded.amount == amount)
    }

    @Test
    func `decodeVaultInstruction round-trips a withdraw`() throws {
        let amount: UInt64 = 12
        let data = coder.encodeWithdraw(amount: amount)
        let decoded = try coder.decodeVaultInstruction(from: data)
        #expect(decoded.kind == .withdraw)
        #expect(decoded.amount == amount)
    }

    @Test
    func `decodeVaultInstruction round-trips UInt64 max as withdraw`() throws {
        let data = coder.encodeWithdraw(amount: UInt64.max)
        let decoded = try coder.decodeVaultInstruction(from: data)
        #expect(decoded.kind == .withdraw)
        #expect(decoded.amount == UInt64.max)
    }

    @Test
    func `decodeVaultInstruction rejects unknown discriminator`() {
        let bogus = Data(repeating: 0xAA, count: 16)
        #expect(throws: BorshCoderError.self) {
            try coder.decodeVaultInstruction(from: bogus)
        }
    }

    @Test
    func `decodeVaultInstruction rejects payload shorter than 16 bytes`() {
        let short = Data(repeating: 0x00, count: 10)
        #expect(throws: BorshCoderError.invalidInputData) {
            try coder.decodeVaultInstruction(from: short)
        }
    }
}

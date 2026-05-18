//
//  VaultProgramTests.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 18/05/2026.
//

import CoreEntities
import Foundation
import Testing
@testable import CoreInfrastructure

@Suite("VaultProgram")
struct VaultProgramTests {
    // MARK: Encode deposit

    @Test
    func `encodeAmountInstruction deposit with amount 1000 produces discriminator plus u64 little-endian`() {
        // 1000 == 0x3E8 → little-endian bytes: E8 03 00 00 00 00 00 00
        let expected = Data([242, 35, 198, 137, 82, 225, 242, 182])
            + Data([0xE8, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        #expect(VaultProgram.encodeAmountInstruction(name: "deposit", amount: 1000) == expected)
    }

    @Test
    func `encodeAmountInstruction deposit with zero amount produces discriminator plus eight zero bytes`() {
        let expected = Data([242, 35, 198, 137, 82, 225, 242, 182])
            + Data(repeating: 0x00, count: 8)
        #expect(VaultProgram.encodeAmountInstruction(name: "deposit", amount: 0) == expected)
    }

    @Test
    func `encodeAmountInstruction deposit with UInt64 max produces discriminator plus eight 0xFF bytes`() {
        let expected = Data([242, 35, 198, 137, 82, 225, 242, 182])
            + Data(repeating: 0xFF, count: 8)
        #expect(VaultProgram.encodeAmountInstruction(name: "deposit", amount: UInt64.max) == expected)
    }

    @Test
    func `encodeAmountInstruction total layout is 16 bytes`() {
        #expect(VaultProgram.encodeAmountInstruction(name: "deposit", amount: 1000).count == 16)
    }

    // MARK: Encode withdraw

    @Test
    func `encodeAmountInstruction withdraw with amount 1000 produces discriminator plus u64 little-endian`() {
        let expected = Data([183, 18, 70, 156, 148, 109, 161, 34])
            + Data([0xE8, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        #expect(VaultProgram.encodeAmountInstruction(name: "withdraw", amount: 1000) == expected)
    }

    @Test
    func `encodeAmountInstruction withdraw with zero amount produces discriminator plus eight zero bytes`() {
        let expected = Data([183, 18, 70, 156, 148, 109, 161, 34])
            + Data(repeating: 0x00, count: 8)
        #expect(VaultProgram.encodeAmountInstruction(name: "withdraw", amount: 0) == expected)
    }

    @Test
    func `encodeAmountInstruction withdraw with UInt64 max produces discriminator plus eight 0xFF bytes`() {
        let expected = Data([183, 18, 70, 156, 148, 109, 161, 34])
            + Data(repeating: 0xFF, count: 8)
        #expect(VaultProgram.encodeAmountInstruction(name: "withdraw", amount: UInt64.max) == expected)
    }

    // MARK: Decode instruction

    @Test
    func `decodeInstruction round-trips a deposit`() throws {
        let amount: UInt64 = 5_000_000
        let data = VaultProgram.encodeAmountInstruction(name: "deposit", amount: amount)
        let decoded = try VaultProgram.decodeInstruction(data)
        #expect(decoded.kind == .deposit)
        #expect(decoded.amount == amount)
    }

    @Test
    func `decodeInstruction round-trips a withdraw`() throws {
        let amount: UInt64 = 12
        let data = VaultProgram.encodeAmountInstruction(name: "withdraw", amount: amount)
        let decoded = try VaultProgram.decodeInstruction(data)
        #expect(decoded.kind == .withdraw)
        #expect(decoded.amount == amount)
    }

    @Test
    func `decodeInstruction round-trips UInt64 max as withdraw`() throws {
        let data = VaultProgram.encodeAmountInstruction(name: "withdraw", amount: UInt64.max)
        let decoded = try VaultProgram.decodeInstruction(data)
        #expect(decoded.kind == .withdraw)
        #expect(decoded.amount == UInt64.max)
    }

    @Test
    func `decodeInstruction rejects unknown discriminator`() {
        let bogus = Data(repeating: 0xAA, count: 16)
        #expect(throws: BorshCoderError.self) {
            try VaultProgram.decodeInstruction(bogus)
        }
    }

    @Test
    func `decodeInstruction rejects payload shorter than 16 bytes`() {
        let short = Data(repeating: 0x00, count: 10)
        #expect(throws: BorshCoderError.invalidInputData) {
            try VaultProgram.decodeInstruction(short)
        }
    }
}

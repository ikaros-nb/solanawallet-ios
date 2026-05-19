//
//  TokenMintStateDecodingTests.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 19/05/2026.
//

import Foundation
@preconcurrency import SolanaSwift
import Testing
@testable import CoreInfrastructure

/// `SolanaClient+WalletReader` uses `TokenMintState` to decode the mint account of *both*
/// classic SPL Token and Token-2022 mints, on the premise that the 82-byte layout is shared
/// and `BinaryReader` ignores any trailing extension bytes. These tests pin that contract.
@Suite("TokenMintState decoding")
struct TokenMintStateDecodingTests {
    @Test
    func `decodes a classic 82-byte mint and extracts decimals`() throws {
        let buffer = Self.classicMintBuffer(decimals: 6)
        #expect(buffer.count == 82)

        var reader = BinaryReader(bytes: [UInt8](buffer))
        let state = try TokenMintState(from: &reader)

        #expect(state.decimals == 6)
        #expect(state.isInitialized)
    }

    @Test
    func `decodes a Token-2022 mint with extension trailer and ignores trailing bytes`() throws {
        // Classic 82-byte prefix + Token-2022 accountType byte + an arbitrary TLV-shaped trailer.
        // BinaryReader doesn't validate that all bytes were consumed, so decimals must still come
        // through correctly regardless of what follows.
        let prefix = Self.classicMintBuffer(decimals: 9)
        let accountType = Data([0x01])
        // Fake extension TLV: type=0x07 (MetadataPointer), length=0x0040, then 64 bytes of payload.
        let extensionTLV = Data([0x07, 0x00, 0x40, 0x00]) + Data(repeating: 0xAB, count: 64)
        let buffer = prefix + accountType + extensionTLV
        #expect(buffer.count > 82)

        var reader = BinaryReader(bytes: [UInt8](buffer))
        let state = try TokenMintState(from: &reader)

        #expect(state.decimals == 9)
        #expect(state.isInitialized)
    }

    // MARK: - Helpers

    /// Builds a valid 82-byte classic SPL Token mint buffer with the requested decimals.
    /// All other fields are filled with deterministic zero/one values that satisfy the
    /// `TokenMintState` borsh decoder.
    private static func classicMintBuffer(decimals: UInt8) -> Data {
        var data = Data()
        data += Self.uint32LE(0) // mintAuthorityOption = None
        data += Data(repeating: 0, count: 32) // mintAuthority slot (32 bytes, content irrelevant when option=0)
        data += Self.uint64LE(1_000_000) // supply
        data.append(decimals) // decimals
        data.append(1) // isInitialized = true
        data += Self.uint32LE(0) // freezeAuthorityOption = None
        data += Data(repeating: 0, count: 32) // freezeAuthority slot
        return data
    }

    private static func uint32LE(_ value: UInt32) -> Data {
        var littleEndian = value.littleEndian
        return Data(bytes: &littleEndian, count: MemoryLayout<UInt32>.size)
    }

    private static func uint64LE(_ value: UInt64) -> Data {
        var littleEndian = value.littleEndian
        return Data(bytes: &littleEndian, count: MemoryLayout<UInt64>.size)
    }
}

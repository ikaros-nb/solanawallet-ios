//
//  SecureEnclaveManagerTests.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 22/04/2026.
//

import CoreInfrastructure
import CryptoKit
import Foundation
import Testing

struct SecureEnclaveManagerTests {
    @Test(.enabled(if: SecureEnclave.isAvailable))
    func `roundtrip with empty plaintext`() throws {
        let manager = try makeSUT()
        defer { try? manager.reset() }

        let blob = try manager.encrypt(Data())
        #expect(try manager.decrypt(blob) == Data())
    }

    @Test(.enabled(if: SecureEnclave.isAvailable))
    func `roundtrip with ed25519-sized plaintext`() throws {
        let manager = try makeSUT()
        defer { try? manager.reset() }

        let plaintext = Data((0..<64).map { UInt8($0) }) // 64 octets = keypair size
        let blob = try manager.encrypt(plaintext)
        #expect(try manager.decrypt(blob) == plaintext)
    }

    @Test(.enabled(if: SecureEnclave.isAvailable))
    func `each encrypt produces a different blob`() throws {
        let manager = try makeSUT()
        defer { try? manager.reset() }

        let plaintext = Data("same input".utf8)
        let blob1 = try manager.encrypt(plaintext)
        let blob2 = try manager.encrypt(plaintext)
        #expect(blob1 != blob2)
    }

    @Test(.enabled(if: SecureEnclave.isAvailable))
    func `tampered blob fails to decrypt`() throws {
        let manager = try makeSUT()
        defer { try? manager.reset() }

        var blob = try manager.encrypt(Data("secret".utf8))
        blob[blob.count - 1] ^= 0xFF // flip le dernier octet (dans le tag GCM)

        #expect(throws: (any Error).self) {
            try manager.decrypt(blob)
        }
    }

    @Test(.enabled(if: SecureEnclave.isAvailable))
    func `too short blob throws corruptedCiphertext`() throws {
        let manager = try makeSUT()
        defer { try? manager.reset() }

        #expect(throws: SecureEnclaveManager.Failure.corruptedCiphertext) {
            try manager.decrypt(Data(repeating: 0, count: 10))
        }
    }

    @Test(.enabled(if: SecureEnclave.isAvailable))
    func `decrypt after reset throws`() throws {
        let manager = try makeSUT()
        defer { try? manager.reset() }

        let blob = try manager.encrypt(Data("before reset".utf8))
        try manager.reset()

        #expect(throws: (any Error).self) {
            try manager.decrypt(blob)
        }
    }

    private func makeSUT() throws -> SecureEnclaveManager {
        let manager = try SecureEnclaveManager(
            keychainService: "com.ikaros.SolanaWallet.tests"
        )
        try manager.reset()
        return manager
    }
}

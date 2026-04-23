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
    func `encrypt and decrypt`() throws {
        let manager = try SecureEnclaveManager(
            keychainService: "com.ikaros.SolanaWallet.tests"
        )
        try manager.reset()
        defer { try? manager.reset() }

        let plaintext = Data("hello secure enclave".utf8)
        let blob = try manager.encrypt(plaintext)
        let recovered = try manager.decrypt(blob)

        #expect(plaintext == recovered)
    }
}

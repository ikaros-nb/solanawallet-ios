//
//  KeychainWalletStoreTests.swift
//  SolanaWallet
//
//  Created by Nicolas Bouème on 28/04/2026.
//

import CoreInfrastructure
import Foundation
import Testing

@Suite("KeychainWalletStore", .serialized)
struct KeychainWalletStoreTests {
    let store: KeychainWalletStore

    init() throws {
        let base = "com.ikaros.SolanaWallet"
        let seService = "\(base).secure-enclave.tests"
        let walletService = "\(base).wallet.tests"
        let secureEnclave = try SecureEnclaveManager(keychainService: seService)
        store = KeychainWalletStore(
            keychainService: walletService,
            secureEnclave: secureEnclave
        )
        try store.reset()
    }

    @Test
    func `savePublicKey + loadPublicKey roundtrip returns the same bytes`() throws {
        let pubkey = Data([0x01, 0x02, 0x03, 0x04])
        try store.savePublicKey(pubkey)
        #expect(try store.loadPublicKey() == pubkey)
    }

    @Test
    func `loadPublicKey returns nil when no entry is stored`() throws {
        #expect(try store.loadPublicKey() == nil)
    }

    @Test
    func `savePublicKey overwrites an existing entry`() throws {
        try store.savePublicKey(Data([0x01]))
        try store.savePublicKey(Data([0x02]))
        #expect(try store.loadPublicKey() == Data([0x02]))
    }

    @Test
    func `keypair roundtrip via withSigningSession exposes the original plaintext`() throws {
        let plaintext = Data([0xDE, 0xAD, 0xBE, 0xEF])
        try store.saveKeypair(plaintext)
        let received = try store.withSigningSession(reason: "test") { $0 }
        #expect(received == plaintext)
    }

    @Test
    func `saveKeypair throws keypairAlreadyExists when called twice`() throws {
        try store.saveKeypair(Data([0x01]))
        #expect(throws: KeychainWalletStore.Failure.keypairAlreadyExists) {
            try store.saveKeypair(Data([0x02]))
        }
    }

    @Test
    func `withSigningSession throws .walletNotFound when no keypair is stored`() {
        #expect(throws: KeychainWalletStore.Failure.walletNotFound) {
            try store.withSigningSession(reason: "test") { _ in }
        }
    }

    @Test
    func `withSigningSession does not invoke block when no keypair is stored`() async {
        _ = await confirmation("block must not be invoked", expectedCount: 0) { blockCalled in
            #expect(throws: KeychainWalletStore.Failure.walletNotFound) {
                try store.withSigningSession(reason: "test") { _ in
                    blockCalled()
                }
            }
        }
    }

    @Test
    func `reset clears both pubkey and keypair entries`() throws {
        try store.savePublicKey(Data([0x01]))
        try store.saveKeypair(Data([0x02]))

        try store.reset()

        #expect(try store.loadPublicKey() == nil)
        #expect(throws: KeychainWalletStore.Failure.walletNotFound) {
            try store.withSigningSession(reason: "test") { _ in }
        }
    }
}

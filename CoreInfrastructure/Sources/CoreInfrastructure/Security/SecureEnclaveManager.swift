//
//  SecureEnclaveManager.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 22/04/2026.
//

import CryptoKit
import Foundation

public struct SecureEnclaveManager: Sendable {
    public enum Failure: Error, Equatable, Sendable {
        case corruptedCiphertext
        case keychainError(OSStatus)
        case secureEnclaveUnavailable
        case unknown
    }

    private let keychainService: String
    private static let keychainAccount = "se-encryption-key"

    public init(
        keychainService: String = "com.ikaros.SolanaWallet"
    ) throws {
        guard SecureEnclave.isAvailable else {
            throw Failure.secureEnclaveUnavailable
        }
        self.keychainService = keychainService
    }

    public func encrypt(_ plaintext: Data) throws -> Data {
        let seKey = try loadOrCreateEncryptionKey()

        // On-memory key (Outside SecureEnclave)
        let ephemeral = P256.KeyAgreement.PrivateKey()

        // ECDH
        let shared = try ephemeral.sharedSecretFromKeyAgreement(with: seKey.publicKey)

        // HKDF
        let symKey = shared.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Self.hkdfInfo,
            outputByteCount: 32
        )

        // AES-GCM seal
        let sealed = try AES.GCM.seal(plaintext, using: symKey)
        guard let combined = sealed.combined else {
            throw Failure.unknown
        }

        // blob = public ephemeral ∥ (nonce ∥ ciphertext ∥ tag)
        return ephemeral.publicKey.rawRepresentation + combined
    }

    public func decrypt(_ ciphertext: Data) throws -> Data {
        let seKey = try loadOrCreateEncryptionKey()

        guard ciphertext.count >= Self.minimumCiphertextSize else {
            throw Failure.corruptedCiphertext
        }
        let ephemeralPubBytes = ciphertext.prefix(Self.ephemeralPublicKeySize)
        let sealedCombined = ciphertext.dropFirst(Self.ephemeralPublicKeySize)

        let ephemeralPub = try P256.KeyAgreement.PublicKey(
            rawRepresentation: ephemeralPubBytes
        )

        // ECDH
        let shared = try seKey.sharedSecretFromKeyAgreement(with: ephemeralPub)

        // HKDF
        let symKey = shared.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Self.hkdfInfo,
            outputByteCount: 32
        )

        // AES-GCM open
        let sealed = try AES.GCM.SealedBox(combined: sealedCombined)
        return try AES.GCM.open(sealed, using: symKey)
    }

    public func reset() throws {
        try deleteEncryptionKey()
    }

    // MARK: Private

    private static let hkdfInfo = Data("SolanaWallet.se-encryption.v1".utf8)
    private static let ephemeralPublicKeySize = 64
    private static let minimumCiphertextSize = ephemeralPublicKeySize + 12 + 16 // = 92
    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: Self.keychainAccount
        ]
    }

    private func loadOrCreateEncryptionKey() throws -> SecureEnclave.P256.KeyAgreement.PrivateKey {
        if let existing = try lookupEncryptionKey() {
            return existing
        }
        let fresh = try SecureEnclave.P256.KeyAgreement.PrivateKey()
        try storeEncryptionKey(fresh.dataRepresentation)
        return fresh
    }

    private func lookupEncryptionKey() throws -> SecureEnclave.P256.KeyAgreement.PrivateKey? {
        var query = baseQuery
        query[kSecReturnData as String] = true

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw Failure.unknown
            }
            return try SecureEnclave.P256.KeyAgreement.PrivateKey(dataRepresentation: data)
        case errSecItemNotFound:
            return nil
        default:
            throw Failure.keychainError(status)
        }
    }

    private func storeEncryptionKey(_ representation: Data) throws {
        var attributes = baseQuery
        attributes[kSecValueData as String] = representation
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw Failure.keychainError(status)
        }
    }

    private func deleteEncryptionKey() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        switch status {
        case errSecSuccess, errSecItemNotFound:
            return
        default:
            throw Failure.keychainError(status)
        }
    }
}

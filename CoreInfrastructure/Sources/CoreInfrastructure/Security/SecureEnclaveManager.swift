//
//  SecureEnclaveManager.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 22/04/2026.
//

import CryptoKit
import Foundation

public struct SecureEnclaveManager: Sendable {
    public enum Failure: Error, Sendable {
        case keychainError(OSStatus)
        case unknown
    }

    public init() {}

    public func encrypt(_ plaintext: Data) throws -> Data {
        throw Failure.unknown
    }

    public func decrypt(_ ciphertext: Data) throws -> Data {
        throw Failure.unknown
    }

    // MARK: Private

    private static let keychainService = "com.ikaros.SolanaWallet"
    private static let keychainAccount = "se-encryption-key"
    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
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
        var query = Self.baseQuery
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
        var attributes = Self.baseQuery
        attributes[kSecValueData as String] = representation
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw Failure.keychainError(status)
        }
    }

    private func deleteEncryptionKey() throws {
        let status = SecItemDelete(Self.baseQuery as CFDictionary)
        switch status {
        case errSecSuccess, errSecItemNotFound:
            return
        default:
            throw Failure.keychainError(status)
        }
    }
}

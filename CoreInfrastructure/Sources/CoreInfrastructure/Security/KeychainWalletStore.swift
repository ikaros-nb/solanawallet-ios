//
//  KeychainWalletStore.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 28/04/2026.
//

import Foundation

public struct KeychainWalletStore: Sendable {
    public enum Failure: Error, Equatable, Sendable {
        case keychainError(OSStatus)
        case unknown
    }

    private let keychainService: String
    private let secureEnclave: SecureEnclaveManager
    private static let pubkeyAccount = "solana-pubkey"
    private static let keypairAccount = "solana-keypair"

    public init(
        keychainService: String = "com.ikaros.SolanaWallet.wallet",
        secureEnclave: SecureEnclaveManager
    ) {
        self.keychainService = keychainService
        self.secureEnclave = secureEnclave
    }

    func savePublicKey(_ data: Data) throws {
        let mutableAttributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let addAttributes = pubkeyQuery.merging(mutableAttributes) { _, new in new }

        let status = SecItemAdd(addAttributes as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            let updateStatus = SecItemUpdate(pubkeyQuery as CFDictionary, mutableAttributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw Failure.keychainError(updateStatus)
            }
        default:
            throw Failure.keychainError(status)
        }
    }

    func loadPublicKey() throws -> Data? {
        var query = pubkeyQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw Failure.unknown
            }
            return data
        case errSecItemNotFound:
            return nil
        default:
            throw Failure.keychainError(status)
        }
    }

    func saveKeypair(_ keypair: Data) throws {
        fatalError("TODO")
    }

    func withSigningSession<T: Sendable>(reason: String, _ block: @Sendable (Data) throws -> T) async throws -> T {
        fatalError("TODO")
    }

    func reset() throws {
        fatalError("TODO")
    }

    // MARK: Private

    private var pubkeyQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: Self.pubkeyAccount
        ]
    }
}

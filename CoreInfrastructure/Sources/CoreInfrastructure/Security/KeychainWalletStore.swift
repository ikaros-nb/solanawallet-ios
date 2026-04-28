//
//  KeychainWalletStore.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 28/04/2026.
//

import Foundation
import LocalAuthentication

public struct KeychainWalletStore: Sendable {
    /// Errors raised by the store itself. `SecureEnclaveManager` errors
    /// propagate as-is from `saveKeypair` and `withSigningSession` — they are
    /// not wrapped in `Failure`.
    public enum Failure: Error, Equatable, Sendable {
        case accessControlCreationFailed
        case biometryFailed
        case keychainError(OSStatus)
        case keypairAlreadyExists
        case userCancelled
        case walletNotFound
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

    public func savePublicKey(_ data: Data) throws {
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

    public func loadPublicKey() throws -> Data? {
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

    /// Stores the encrypted keypair. Intentionally non-idempotent: an existing
    /// wallet must be explicitly destroyed via `reset()` before a new one is
    /// stored, to prevent accidental overwrites.
    public func saveKeypair(_ keypair: Data) throws {
        var error: Unmanaged<CFError>?
        guard
            let access = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                [.biometryCurrentSet, .or, .devicePasscode],
                &error
            )
        else {
            error?.release()
            throw Failure.accessControlCreationFailed
        }

        var attributes = keypairQuery
        attributes[kSecAttrAccessControl as String] = access

        var blob = try secureEnclave.encrypt(keypair)
        attributes[kSecValueData as String] = blob
        defer { blob.resetBytes(in: 0..<blob.count) }

        let status = SecItemAdd(attributes as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            throw Failure.keypairAlreadyExists
        default:
            throw Failure.keychainError(status)
        }
    }

    public func withSigningSession<T: Sendable>(
        reason: String,
        _ block: @Sendable (Data) throws -> T
    ) throws -> T {
        let context = LAContext()
        context.localizedReason = reason

        var query = keypairQuery
        query[kSecReturnData as String] = true
        query[kSecUseAuthenticationContext as String] = context
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let blob = result as? Data else {
                throw Failure.unknown
            }
            var keypair = try secureEnclave.decrypt(blob)
            defer { keypair.resetBytes(in: 0..<keypair.count) }
            return try block(keypair)
        case errSecUserCanceled:
            throw Failure.userCancelled
        case errSecItemNotFound:
            throw Failure.walletNotFound
        case errSecAuthFailed:
            throw Failure.biometryFailed
        default:
            throw Failure.keychainError(status)
        }
    }

    public func reset() throws {
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

    private var keypairQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: Self.keypairAccount
        ]
    }
}

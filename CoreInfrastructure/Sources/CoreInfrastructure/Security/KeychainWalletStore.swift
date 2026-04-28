//
//  KeychainWalletStore.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 28/04/2026.
//

import Foundation
import LocalAuthentication

/// Persists a Solana wallet across two Keychain items under the same service:
///
/// - **Public key** (`solana-pubkey`): plaintext, accessible when unlocked.
///   No user prompt on read or write.
/// - **Encrypted keypair** (`solana-keypair`): sealed by ``SecureEnclaveManager``
///   and gated by current biometry **or** device passcode. Reads trigger a
///   system authentication prompt; writes and deletes do not.
public struct KeychainWalletStore: Sendable {
    /// Errors raised by the store itself. `SecureEnclaveManager` errors
    /// propagate as-is from `saveKeypair` and `withSigningSession`.
    public enum Failure: Error, Equatable, Sendable {
        case accessControlCreationFailed
        /// `errSecAuthFailed`: biometry / passcode attempt rejected.
        case biometryFailed
        case keychainError(OSStatus)
        /// A keypair is already stored; clear it via ``reset()`` first.
        case keypairAlreadyExists
        /// `errSecUserCanceled`: user dismissed the authentication prompt.
        case userCancelled
        /// `errSecItemNotFound`: no keypair stored under this service.
        case walletNotFound
        case unknown
    }

    private let keychainService: String
    private let secureEnclave: SecureEnclaveManager
    private static let pubkeyAccount = "solana-pubkey"
    private static let keypairAccount = "solana-keypair"

    /// Both items live under the same `keychainService`; use distinct values
    /// to isolate wallets between environments or tests.
    public init(
        keychainService: String = "com.ikaros.SolanaWallet.wallet",
        secureEnclave: SecureEnclaveManager
    ) {
        self.keychainService = keychainService
        self.secureEnclave = secureEnclave
    }

    /// Stores or replaces the public key. Idempotent.
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

    /// Returns the stored public key, or `nil` if none exists.
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

    /// Encrypts and stores the keypair. Non-idempotent: clear via ``reset()``
    /// first, to avoid overwriting an active wallet.
    ///
    /// Re-enrolling biometry after this call invalidates the item; only the
    /// device passcode fallback remains usable.
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

    /// Prompts the user (Face ID / Touch ID, passcode fallback), decrypts the
    /// keypair, and hands the plaintext to `block`. `reason` is shown in the
    /// prompt.
    ///
    /// The plaintext is zeroed when `block` returns or throws — callers must
    /// not let it escape the closure (capture, return, async hop) or the
    /// zeroization is moot.
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

    /// Removes both Keychain items. Best-effort: both deletes are attempted
    /// even if the first fails, and on throw the store state is undefined.
    ///
    /// Does not destroy the Secure Enclave encryption key — see
    /// ``SecureEnclaveManager/reset()`` for that.
    public func reset() throws {
        let statuses = [
            SecItemDelete(pubkeyQuery as CFDictionary),
            SecItemDelete(keypairQuery as CFDictionary)
        ]
        for status in statuses where status != errSecSuccess && status != errSecItemNotFound {
            throw Failure.keychainError(status)
        }
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

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
        /// A Keychain operation returned the wrapped `OSStatus`.
        case keychainError(OSStatus)
        /// The ciphertext is shorter than the minimum envelope or malformed.
        case corruptedCiphertext
        /// A Keychain item already exists for this service/account pair.
        case handleAlreadyExists
        /// The host has no Secure Enclave (older hardware, Intel simulator).
        case secureEnclaveUnavailable
        /// An unexpected internal invariant was violated; indicates a bug.
        case unknown
    }

    private let keychainService: String
    private static let keychainAccount = "se-encryption-key"

    /// Creates a manager bound to a Keychain service namespace.
    ///
    /// Apple Silicon simulators expose the host's Secure Enclave and are
    /// accepted; older hardware and Intel simulators are rejected. Instances
    /// sharing the same `keychainService` share the same underlying key.
    ///
    /// - Parameter keychainService: `kSecAttrService` used to scope the stored
    ///   key handle. Use distinct values to isolate keys between wallets,
    ///   tests, or environments.
    /// - Throws: ``Failure/secureEnclaveUnavailable`` if no Secure Enclave
    ///   is available on the host.
    public init(
        keychainService: String = "com.ikaros.SolanaWallet.secure-enclave"
    ) throws {
        guard SecureEnclave.isAvailable else {
            throw Failure.secureEnclaveUnavailable
        }
        self.keychainService = keychainService
    }

    /// Encrypts `plaintext` under the device's Secure Enclave key.
    ///
    /// Implements ECIES-style hybrid encryption:
    /// 1. Generate a fresh ephemeral P-256 key pair in process memory.
    /// 2. Derive a shared secret via ECDH between the ephemeral private
    ///    key and the Secure Enclave key's public half.
    /// 3. Expand the shared secret into a 256-bit AES key via HKDF-SHA256
    ///    with a versioned `sharedInfo` string.
    /// 4. Seal `plaintext` with AES-GCM (random nonce, per-call).
    /// 5. Return `ephemeralPublicKey ∥ nonce ∥ ciphertext ∥ tag`.
    ///
    /// The ephemeral private key is discarded at the end of the call, so
    /// each ciphertext carries a unique public key and nonce. This is not
    /// forward secrecy — the Secure Enclave key is long-term, so its
    /// compromise would expose every past ciphertext. The ephemeral only
    /// guarantees nonce/key uniqueness per call.
    ///
    /// Agnostic to payload content: the manager has no knowledge of
    /// Solana keypairs or any other higher-level structure (see ADR-002
    /// D9). Callers layer their own serialization on top.
    ///
    /// - Parameter plaintext: Arbitrary bytes to encrypt. Empty input is valid.
    /// - Returns: A self-contained blob decryptable only by ``decrypt(_:)``
    ///   on this device, via an instance bound to the same `keychainService`.
    ///   The underlying Keychain item uses
    ///   `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, so the blob is
    ///   not portable across devices.
    /// - Throws: ``Failure/unknown`` if AES-GCM fails to produce a
    ///   combined representation; rethrows Secure Enclave, Keychain, or
    ///   CryptoKit errors.
    public func encrypt(_ plaintext: Data) throws -> Data {
        let seKey = try loadOrCreateEncryptionKey()
        let ephemeral = P256.KeyAgreement.PrivateKey()
        let shared = try ephemeral.sharedSecretFromKeyAgreement(with: seKey.publicKey)
        let symKey = shared.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Self.hkdfInfo,
            outputByteCount: 32
        )
        let sealed = try AES.GCM.seal(plaintext, using: symKey)
        guard let combined = sealed.combined else {
            throw Failure.unknown
        }
        return ephemeral.publicKey.rawRepresentation + combined
    }

    /// Decrypts a blob previously produced by ``encrypt(_:)``.
    ///
    /// Reverses the ECIES-style envelope:
    /// 1. Split the blob into ephemeral public key (first 64 bytes) and
    ///    the AES-GCM combined representation (nonce ∥ ciphertext ∥ tag).
    /// 2. Derive the shared secret via ECDH between the Secure Enclave
    ///    key and the ephemeral public key. The ECDH operation itself
    ///    runs inside the Secure Enclave — the private scalar never
    ///    reaches process memory.
    /// 3. Re-derive the AES-GCM key via HKDF-SHA256 with the same
    ///    versioned `sharedInfo` used during encryption.
    /// 4. Open the sealed box; AES-GCM's authentication tag validates
    ///    both the ciphertext and the attached ephemeral public key (via
    ///    the derived key).
    ///
    /// Fails closed on any tampering: a single bit flipped anywhere in
    /// the blob produces a tag mismatch rather than partial plaintext.
    /// Input shorter than the minimum envelope size (92 bytes) is
    /// rejected up front with ``Failure/corruptedCiphertext``.
    ///
    /// - Parameter ciphertext: A blob produced by ``encrypt(_:)`` on this
    ///   device, via an instance bound to the same `keychainService`.
    /// - Returns: The original plaintext.
    /// - Throws: ``Failure/corruptedCiphertext`` if the blob is shorter
    ///   than the minimum envelope; rethrows CryptoKit errors for an
    ///   invalid ephemeral public key or a failed AES-GCM open (tampered
    ///   blob, wrong Secure Enclave key, mismatched `keychainService`).
    public func decrypt(_ ciphertext: Data) throws -> Data {
        guard ciphertext.count >= Self.minimumCiphertextSize else {
            throw Failure.corruptedCiphertext
        }
        let ephemeralPubBytes = ciphertext.prefix(Self.ephemeralPublicKeySize)
        let sealedCombined = ciphertext.dropFirst(Self.ephemeralPublicKeySize)
        let ephemeralPub = try P256.KeyAgreement.PublicKey(
            rawRepresentation: ephemeralPubBytes
        )
        let seKey = try loadOrCreateEncryptionKey()
        let shared = try seKey.sharedSecretFromKeyAgreement(with: ephemeralPub)
        let symKey = shared.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Self.hkdfInfo,
            outputByteCount: 32
        )
        let sealed = try AES.GCM.SealedBox(combined: sealedCombined)
        return try AES.GCM.open(sealed, using: symKey)
    }

    /// Destroys the Secure Enclave encryption key and invalidates every
    /// ciphertext ever produced by this manager.
    ///
    /// Deletes the Keychain-stored handle; with no remaining reference,
    /// the Secure Enclave releases the underlying private key material.
    /// The next call to ``encrypt(_:)`` or ``decrypt(_:)`` mints a fresh
    /// key, against which prior blobs cannot be decrypted.
    ///
    /// Irreversible. Intended for wallet-wipe flows (user-initiated
    /// reset, logout with local key destruction). Idempotent: succeeds
    /// silently if no key is currently stored.
    ///
    /// - Throws: ``Failure/keychainError(_:)`` if the deletion fails for
    ///   any reason other than the item being absent.
    public func reset() throws {
        try deleteEncryptionKey()
    }

    // MARK: Private

    private static let hkdfInfo = Data("SolanaWallet.se-encryption.v1".utf8)
    /// Size in bytes of an uncompressed P-256 public key in raw representation (X ∥ Y).
    private static let ephemeralPublicKeySize = 64
    /// Minimum valid ciphertext size: ephemeral public key (64) + AES-GCM nonce (12) + tag (16) = 92.
    private static let minimumCiphertextSize = ephemeralPublicKeySize + 12 + 16
    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: Self.keychainAccount
        ]
    }

    /// Returns the Secure Enclave encryption key handle, creating one on first use.
    ///
    /// Resolves the "load existing or generate new" step of every encrypt
    /// and decrypt call into a single handle. A fresh key is minted inside
    /// the Secure Enclave only when no handle is stored in the Keychain,
    /// so repeated calls are cheap after the first one.
    ///
    /// Safe under concurrent first-use: if two callers race past the
    /// initial lookup, the losing ``SecItemAdd`` surfaces
    /// ``Failure/handleAlreadyExists`` and is recovered by re-reading the
    /// winner's handle. The fresh key generated by the loser is discarded
    /// and its material is released by the Secure Enclave.
    ///
    /// - Returns: A usable Secure Enclave key handle for ECDH.
    /// - Throws: ``Failure/keychainError(_:)`` for unrecoverable Keychain
    ///   failures; ``Failure/unknown`` if the post-race lookup unexpectedly
    ///   finds no item; rethrows any error from key generation.
    private func loadOrCreateEncryptionKey() throws -> SecureEnclave.P256.KeyAgreement.PrivateKey {
        if let existing = try lookupEncryptionKey() {
            return existing
        }
        let fresh = try SecureEnclave.P256.KeyAgreement.PrivateKey()
        do {
            try storeEncryptionKey(fresh.dataRepresentation)
            return fresh
        } catch Failure.handleAlreadyExists {
            guard let winner = try lookupEncryptionKey() else {
                throw Failure.unknown
            }
            return winner
        }
    }

    /// Loads the Secure Enclave encryption key handle from the Keychain, if present.
    ///
    /// The rehydrated value only references the key inside the Secure Enclave;
    /// the private material never reaches process memory. A missing item is an
    /// expected state (first launch, post-reset) and is reported as `nil`.
    ///
    /// - Returns: The existing key handle, or `nil` if none is stored.
    /// - Throws: ``Failure/keychainError(_:)`` for any Keychain failure
    ///   other than `errSecItemNotFound`; ``Failure/unknown`` if the
    ///   Keychain returns a value that is not `Data`.
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

    /// Persists a Secure Enclave encryption key handle in the Keychain.
    ///
    /// Only the opaque handle (`dataRepresentation`) is written; the private
    /// key material never leaves the Secure Enclave. The item is stored with
    /// `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` so it cannot be
    /// restored to another device and is unavailable before the first
    /// post-boot unlock.
    ///
    /// Not idempotent: callers must ensure no handle is already stored for
    /// the same service/account pair. A concurrent write by another process
    /// or task is surfaced as ``Failure/handleAlreadyExists`` so the caller
    /// can recover by reloading the winning handle.
    ///
    /// - Parameter representation: The `dataRepresentation` of a
    ///   `SecureEnclave.P256.KeyAgreement.PrivateKey`.
    /// - Throws: ``Failure/handleAlreadyExists`` if an item already exists
    ///   at this service/account pair; ``Failure/keychainError(_:)`` for any
    ///   other Keychain failure.
    private func storeEncryptionKey(_ representation: Data) throws {
        var attributes = baseQuery
        attributes[kSecValueData as String] = representation
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(attributes as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            throw Failure.handleAlreadyExists
        default:
            throw Failure.keychainError(status)
        }
    }

    /// Removes the Secure Enclave encryption key handle from the Keychain.
    ///
    /// The private key material held by the Secure Enclave is released once
    /// no handle references it. Any ciphertext produced before this call
    /// becomes permanently undecryptable.
    ///
    /// Idempotent: succeeds silently if no handle is currently stored.
    ///
    /// - Throws: ``Failure/keychainError(_:)`` if the deletion fails for any
    ///   reason other than the item being absent.
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

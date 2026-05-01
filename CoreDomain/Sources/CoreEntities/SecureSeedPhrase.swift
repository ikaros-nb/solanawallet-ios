//
//  SecureSeedPhrase.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 01/05/2026.
//

import Foundation

/// Defense-in-depth wrapper around a BIP39 seed phrase: holds the words in a
/// `[UInt8]` buffer that is zeroed on ``wipe()`` and on `deinit`.
///
/// Swift `String` is immutable and offers no zeroization API, so the value
/// returned by ``read()`` cannot itself be wiped — but its lifetime is bounded
/// by the caller. Drop every reference to the SecureSeedPhrase as soon as the
/// UI is done displaying it and the longest-lived copy of the phrase is gone.
public final class SecureSeedPhrase: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [UInt8]
    private var wiped = false

    public init(words: [String]) {
        let separators = max(0, words.count - 1)
        let totalBytes = words.reduce(separators) { $0 + $1.utf8.count }
        var bytes: [UInt8] = []
        bytes.reserveCapacity(totalBytes)
        for (index, word) in words.enumerated() {
            if index > 0 { bytes.append(0x20) }
            bytes.append(contentsOf: word.utf8)
        }
        storage = bytes
    }

    /// Returns the seed phrase as space-joined words, or `nil` if already wiped.
    public func read() -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard !wiped else { return nil }
        return String(bytes: storage, encoding: .utf8)
    }

    /// Zeroes the underlying buffer. Idempotent.
    public func wipe() {
        lock.lock()
        defer { lock.unlock() }
        guard !wiped else { return }
        for index in storage.indices {
            storage[index] = 0
        }
        storage = []
        wiped = true
    }

    deinit { wipe() }
}

//
//  SecureEnclaveManager.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 22/04/2026.
//

import Foundation

public struct SecureEnclaveManager: Sendable {
    public enum Failure: Error, Sendable {
        case unknown
    }

    public init() {}

    public func encrypt(_ plaintext: Data) throws -> Data {
        throw Failure.unknown
    }

    public func decrypt(_ ciphertext: Data) throws -> Data {
        throw Failure.unknown
    }
}

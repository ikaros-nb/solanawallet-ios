//
//  BiometricAuthenticator.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 07/05/2026.
//

import Foundation

public protocol BiometricAuthenticator: Sendable {
    func canEvaluate() -> Bool
    func evaluate(reason: String) async throws -> Bool

    /// Opaque hash representing the currently enrolled biometric set, suitable
    /// for equality comparison only. `nil` when biometry is unavailable or no
    /// biometric is enrolled — that state is itself a meaningful signal when
    /// compared against a previously stored hash.
    func currentBiometryStateHash() -> Data?
}

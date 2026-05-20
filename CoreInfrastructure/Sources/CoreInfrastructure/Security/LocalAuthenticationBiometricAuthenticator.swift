//
//  LocalAuthenticationBiometricAuthenticator.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 07/05/2026.
//

import CoreDomain
import Foundation
import LocalAuthentication

public struct LocalAuthenticationBiometricAuthenticator: BiometricAuthenticator {
    public init() {}

    public func canEvaluate() -> Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    public func evaluate(reason: String) async throws -> Bool {
        try await LAContext().evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
    }

    public func currentBiometryStateHash() -> Data? {
        // Probe with the biometry-only policy so we only return a hash when an
        // enrolled biometric set actually exists — a passcode-only device must
        // return nil so the detection path can distinguish "no biometry" from
        // "biometry changed".
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return nil
        }
        return context.domainState.biometry.stateHash
    }
}

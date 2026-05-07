//
//  LocalAuthenticationBiometricAuthenticator.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 07/05/2026.
//

import CoreDomain
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
}

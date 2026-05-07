//
//  BiometricAuthenticator.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 07/05/2026.
//

public protocol BiometricAuthenticator: Sendable {
    func canEvaluate() -> Bool
    func evaluate(reason: String) async throws -> Bool
}

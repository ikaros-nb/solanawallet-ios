//
//  SolanaAddressValidator.swift
//  FeatureDashboard
//
//  Created by Nicolas Bouème on 20/05/2026.
//

import Foundation

enum SolanaAddressValidator {
    private static let base58Alphabet = Set("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")

    static func isStructurallyValid(_ candidate: String) -> Bool {
        let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (32...44).contains(trimmed.count) else { return false }
        return trimmed.allSatisfy(base58Alphabet.contains)
    }
}

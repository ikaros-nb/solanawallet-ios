//
//  WalletDependencies.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 06/05/2026.
//

import CoreEntities
import SwiftUI

public extension EnvironmentValues {
    @Entry var walletOnComplete: ((WalletAccount) -> Void)?
}

/// Flow-scoped state for the wallet onboarding navigation stack.
///
/// Owns the live `SecureSeedPhrase` so it never has to ride inside a
/// `Codable` navigation route (which could be persisted via state restoration).
/// Replacing or clearing the phrase wipes the previous one.
@Observable
@MainActor
final class OnboardingSession {
    private(set) var seedPhrase: SecureSeedPhrase?

    func setSeedPhrase(_ newValue: SecureSeedPhrase) {
        seedPhrase?.wipe()
        seedPhrase = newValue
    }

    func clear() {
        seedPhrase?.wipe()
        seedPhrase = nil
    }
}

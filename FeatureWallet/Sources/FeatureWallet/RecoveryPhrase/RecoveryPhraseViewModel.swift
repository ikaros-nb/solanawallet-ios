//
//  RecoveryPhraseViewModel.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 06/05/2026.
//

import CoreDomain
import CoreEntities
import SwiftUI

@Observable
@MainActor
final class RecoveryPhraseViewModel {
    let words: [String]
    private let session: OnboardingSession
    private let walletCreator: (any WalletCreator)?
    private let onComplete: ((WalletAccount) -> Void)?

    init(
        session: OnboardingSession,
        walletCreator: (any WalletCreator)? = nil,
        onComplete: ((WalletAccount) -> Void)? = nil
    ) {
        self.session = session
        self.walletCreator = walletCreator
        self.onComplete = onComplete
        words = session.seedPhrase?.read() ?? []
    }

    func createWallet(router: RecoveryPhraseRouter) async {
        guard let walletCreator, let seedPhrase = session.seedPhrase else { return }

        do {
            let account = try await walletCreator.createWallet(seedPhrase: seedPhrase)
            session.clear()
            onComplete?(account)
        } catch {
            print("Failed to create wallet: \(error)")
        }
    }
}

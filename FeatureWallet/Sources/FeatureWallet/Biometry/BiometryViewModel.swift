//
//  BiometryViewModel.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 06/05/2026.
//

import CoreDomain
import SwiftUI

@Observable
@MainActor
final class BiometryViewModel {
    private let mode: WalletMode
    private let walletCreator: (any WalletCreator)?
    private let authenticator: (any BiometricAuthenticator)?
    private let session: OnboardingSession

    init(
        mode: WalletMode,
        walletCreator: (any WalletCreator)?,
        authenticator: (any BiometricAuthenticator)?,
        session: OnboardingSession
    ) {
        self.mode = mode
        self.walletCreator = walletCreator
        self.authenticator = authenticator
        self.session = session
    }

    func authenticateWithFaceID(
        router: BiometryRouter,
        navigator: WalletNavigator
    ) async {
        guard let authenticator, authenticator.canEvaluate() else {
            router.present(.error)
            return
        }

        let reason = String(localized: .Biometry.requestFaceIDDescription)

        do {
            if try await authenticator.evaluate(reason: reason) {
                nextScreen(navigator: navigator)
            }
        } catch {
            router.present(.error)
        }
    }

    private func nextScreen(navigator: WalletNavigator) {
        switch mode {
        case .create:
            guard let walletCreator else { return }
            session.setSeedPhrase(walletCreator.generateSeedPhrase())
            navigator.push(BiometryRoute.recoveryPhrase(.create))
        case .importViaBIP39:
            navigator.push(BiometryRoute.recoveryPhrase(.importViaBIP39))
        }
    }
}

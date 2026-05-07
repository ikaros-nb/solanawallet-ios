//
//  BiometryViewModel.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 06/05/2026.
//

import CoreDomain
import LocalAuthentication
import SwiftUI

@Observable
@MainActor
final class BiometryViewModel {
    private let mode: WalletMode
    private let walletCreator: (any WalletCreator)?
    private let session: OnboardingSession

    init(
        mode: WalletMode,
        walletCreator: (any WalletCreator)?,
        session: OnboardingSession
    ) {
        self.mode = mode
        self.walletCreator = walletCreator
        self.session = session
    }

    func authenticateWithFaceID(
        router: BiometryRouter,
        navigator: WalletNavigator
    ) async {
        let context = LAContext()
        var error: NSError?

        guard
            context.canEvaluatePolicy(
                .deviceOwnerAuthentication,
                error: &error
            )
        else {
            router.present(.error)
            return
        }

        let reason = String(localized: .Biometry.requestFaceIDDescription)

        do {
            let hasEvaluationSucceeded = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            if hasEvaluationSucceeded {
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

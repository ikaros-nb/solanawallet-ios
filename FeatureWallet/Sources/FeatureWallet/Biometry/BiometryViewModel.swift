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

    func authenticateWithFaceID(router: BiometryRouter) async {
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
                nextScreen(router: router)
            }
        } catch {
            router.present(.error)
        }
    }

    private func nextScreen(router: BiometryRouter) {
        switch mode {
        case .create:
            guard let walletCreator else { return }
            session.setSeedPhrase(walletCreator.generateSeedPhrase())
            router.navigate(to: .createWallet)
        case .importViaBIP39:
            router.navigate(to: .importWallet)
        }
    }
}

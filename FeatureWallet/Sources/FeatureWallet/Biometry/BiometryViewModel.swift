//
//  BiometryViewModel.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 06/05/2026.
//

import LocalAuthentication
import SwiftUI

@Observable
@MainActor
final class BiometryViewModel {
    private let mode: WalletMode

    init(mode: WalletMode) {
        self.mode = mode
    }

    func authenticateWithFaceID(router: BiometryRouter) async {
        let context = LAContext()
        var error: NSError?

        guard
            context.canEvaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                error: &error
            )
        else {
            router.present(.error)
            return
        }

        let reason = String(localized: .Biometry.requestFaceIDDescription)

        do {
            let hasEvaluationSucceeded = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
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
            router.navigate(to: .createWallet)
        case .importWallet:
            router.navigate(to: .importWallet)
        }
    }
}

//
//  BiometryViewModel.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 06/05/2026.
//

import SwiftUI

@Observable
@MainActor
final class BiometryViewModel {
    private let mode: WalletMode

    init(mode: WalletMode) {
        self.mode = mode
    }

    func nextScreen(router: BiometryRouter) {
        switch mode {
        case .create:
            router.navigate(to: .createWallet)
        case .importWallet:
            router.navigate(to: .importWallet)
        }
    }
}

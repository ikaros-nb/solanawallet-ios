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
    let mode: WalletMode

    init(mode: WalletMode) {
        self.mode = mode
    }
}

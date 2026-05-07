//
//  BiometryRoute.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 07/05/2026.
//

enum BiometryRoute: Hashable {
    case recoveryPhrase(WalletMode)
}

enum BiometrySheetRoute: Identifiable {
    case error
    var id: Self {
        self
    }
}

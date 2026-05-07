//
//  WalletNavigator.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 07/05/2026.
//

import SwiftUI

@MainActor
@Observable
final class WalletNavigator {
    var path = NavigationPath()

    func push(_ route: some Hashable) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }
}

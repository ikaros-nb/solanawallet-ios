//
//  WelcomeRouter.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 05/05/2026.
//

import SwiftUI

enum WelcomeRoute: Hashable, Codable {
    case biometry(WalletMode)
}

@MainActor
@Observable
final class WelcomeRouter {
    var path = NavigationPath()

    func navigate(to route: WelcomeRoute) {
        path.append(route)
    }
}

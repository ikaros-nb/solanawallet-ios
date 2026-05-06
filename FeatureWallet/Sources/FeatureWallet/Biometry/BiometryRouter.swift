//
//  BiometryRouter.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 06/05/2026.
//

import SwiftUI

public enum BiometryRoute: Hashable, Codable {
    case createWallet
    case importWallet
}

@MainActor
@Observable
final class BiometryRouter {
    private let push: (BiometryRoute) -> Void

    init(push: @escaping (BiometryRoute) -> Void) {
        self.push = push
    }

    func navigate(to route: BiometryRoute) {
        push(route)
    }
}

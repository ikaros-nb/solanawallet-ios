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

public enum BiometrySheetRoute: Identifiable {
    case error
    public var id: Self {
        self
    }
}

@MainActor
@Observable
final class BiometryRouter {
    private let push: (BiometryRoute) -> Void
    var presentedSheet: BiometrySheetRoute?

    init(push: @escaping (BiometryRoute) -> Void) {
        self.push = push
    }

    func navigate(to route: BiometryRoute) {
        push(route)
    }

    func present(_ sheet: BiometrySheetRoute) {
        presentedSheet = sheet
    }

    func dismissSheet() {
        presentedSheet = nil
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

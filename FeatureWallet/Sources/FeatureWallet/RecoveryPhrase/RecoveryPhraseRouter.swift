//
//  RecoveryPhraseRouter.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 06/05/2026.
//

import SwiftUI

public enum RecoveryPhraseRoute: Hashable, Codable {
    case dashboard
}

public enum RecoveryPhraseSheetRoute: Identifiable {
    case confirmation
    public var id: Self {
        self
    }
}

@MainActor
@Observable
final class RecoveryPhraseRouter {
    private let push: (any Hashable) -> Void
    var presentedSheet: RecoveryPhraseSheetRoute?

    init(push: @escaping (any Hashable) -> Void) {
        self.push = push
    }

    func navigate(to route: RecoveryPhraseRoute) {
        push(route)
    }

    func present(_ sheet: RecoveryPhraseSheetRoute) {
        presentedSheet = sheet
    }

    func dismissSheet() {
        presentedSheet = nil
    }
}

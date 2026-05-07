//
//  RecoveryPhraseRouter.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 06/05/2026.
//

import SwiftUI

@MainActor
@Observable
final class RecoveryPhraseRouter {
    var presentedSheet: RecoveryPhraseSheetRoute?

    func present(_ sheet: RecoveryPhraseSheetRoute) {
        presentedSheet = sheet
    }

    func dismissSheet() {
        presentedSheet = nil
    }
}

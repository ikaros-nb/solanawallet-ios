//
//  BiometryRouter.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 06/05/2026.
//

import SwiftUI

@MainActor
@Observable
final class BiometryRouter {
    var presentedSheet: BiometrySheetRoute?

    func present(_ sheet: BiometrySheetRoute) {
        presentedSheet = sheet
    }

    func dismissSheet() {
        presentedSheet = nil
    }
}

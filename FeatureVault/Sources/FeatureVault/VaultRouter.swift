//
//  VaultRouter.swift
//  FeatureVault
//
//  Created by Nicolas Bouème on 14/05/2026.
//

import SwiftUI

@MainActor
@Observable
final class VaultRouter {
    var presentedSheet: VaultSheetRoute?

    func present(_ sheet: VaultSheetRoute) {
        presentedSheet = sheet
    }

    func dismissSheet() {
        presentedSheet = nil
    }
}

//
//  DashboardRouter.swift
//  FeatureDashboard
//
//  Created by Nicolas Bouème on 18/05/2026.
//

import SwiftUI

@MainActor
@Observable
final class DashboardRouter {
    var presentedSheet: DashboardSheetRoute?

    func present(_ sheet: DashboardSheetRoute) {
        presentedSheet = sheet
    }

    func dismissSheet() {
        presentedSheet = nil
    }
}

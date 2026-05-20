//
//  DashboardDependencies.swift
//  FeatureDashboard
//
//  Created by Nicolas Bouème on 20/05/2026.
//

import SwiftUI

public extension EnvironmentValues {
    @Entry var walletOnRemove: (() async throws -> Void)?
}

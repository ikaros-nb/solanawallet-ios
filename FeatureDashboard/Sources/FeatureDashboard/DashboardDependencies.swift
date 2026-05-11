//
//  DashboardDependencies.swift
//  FeatureDashboard
//
//  Created by Nicolas Bouème on 11/05/2026.
//

import CoreDomain
import SwiftUI

public extension EnvironmentValues {
    @Entry var walletReader: (any WalletReader)?
}
